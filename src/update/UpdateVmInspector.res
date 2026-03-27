// SPDX-License-Identifier: PMPL-1.0-or-later

/// Extracted sub-updater for the VM Inspector panel.
/// Manages the reversible VM visual debugger — step forward/backward,
/// breakpoints, timeline navigation, and state export.

open Model
open Msg

let updateVmInspector = (model: model, msg: vmInspectorMsg): (model, Tea_Cmd.t<msg>) => {
  let vm = model.vmInspector
  switch msg {
  | SetInspectorCategory(cat) => ({...model, vmInspector: {...vm, activeCategory: cat}}, Tea_Cmd.none)
  | ReadVmState => {
      let vmCmd = switch vm.connection {
      | VmFileConnection(path) =>
        VmInspectorCmd.readVmStateFromFile(path, result => VmInspector(VmStateReceived(result)))
      | VmLiveConnection | VmDisconnected =>
        VmInspectorCmd.readVmState(result => VmInspector(VmStateReceived(result)))
      }
      (
        {...model, vmInspector: {...vm, loading: true}},
        Tea_Cmd.batch(list{
          vmCmd,
          TypeLLService.checkGameDataTypes("vm-state", "vm-inspector", result => VmInspector(TypeCheckResult(result))),
        }),
      )
    }
  | VmStateReceived(Ok(jsonStr)) => {
    let parsed = switch Decoders.decodeOption(Tea_Json.value, jsonStr) {
    | Some(json) =>

      let obj = json->JSON.Decode.object->Option.getOr(Dict.make())
      let pc = obj->Dict.get("pc")->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0)
      let stackArr = obj->Dict.get("stack")->Option.flatMap(JSON.Decode.array)->Option.getOr([])
      let stack = stackArr->Array.filterMap(v => v->JSON.Decode.float->Option.map(Float.toInt))
      let memArr = obj->Dict.get("memory")->Option.flatMap(JSON.Decode.array)->Option.getOr([])
      let memory = memArr->Array.filterMap(m => {
        let mObj = m->JSON.Decode.object->Option.getOr(Dict.make())
        let address = mObj->Dict.get("address")->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0)
        let value = mObj->Dict.get("value")->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0)
        let recentRead = mObj->Dict.get("recentRead")->Option.flatMap(JSON.Decode.bool)->Option.getOr(false)
        let recentWrite = mObj->Dict.get("recentWrite")->Option.flatMap(JSON.Decode.bool)->Option.getOr(false)
        Some({
          VmInspectorModel.address: Float.toInt(address),
          value: Float.toInt(value),
          recentRead: recentRead,
          recentWrite: recentWrite,
        })
      })
      let instrArr = obj->Dict.get("instructions")->Option.flatMap(JSON.Decode.array)->Option.getOr([])
      let instructions = instrArr->Array.filterMap(i => {
        let iObj = i->JSON.Decode.object->Option.getOr(Dict.make())
        let index = iObj->Dict.get("index")->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0)
        let mnemonic = iObj->Dict.get("mnemonic")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
        let tierStr = iObj->Dict.get("tier")->Option.flatMap(JSON.Decode.string)->Option.getOr("arithmetic")
        let tier = switch tierStr {
        | "conditionals" => VmInspectorModel.TierConditionals
        | "stack_memory" => TierStackMemory
        | "subroutines" => TierSubroutines
        | "io" => TierIO
        | _ => TierArithmetic
        }
        let hasBreakpoint = iObj->Dict.get("hasBreakpoint")->Option.flatMap(JSON.Decode.bool)->Option.getOr(false)
        let executionCount = iObj->Dict.get("executionCount")->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0)
        Some({
          VmInspectorModel.index: Float.toInt(index),
          mnemonic: mnemonic,
          tier: tier,
          hasBreakpoint: hasBreakpoint,
          executionCount: Float.toInt(executionCount),
        })
      })
      let running = obj->Dict.get("running")->Option.flatMap(JSON.Decode.bool)->Option.getOr(false)
      let totalSteps = obj->Dict.get("totalSteps")->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0)
      let tierCountsArr = obj->Dict.get("tierCounts")->Option.flatMap(JSON.Decode.array)->Option.getOr([])
      let tierCounts = tierCountsArr->Array.filterMap(v => v->JSON.Decode.float->Option.map(Float.toInt))
      Some((Float.toInt(pc), stack, memory, instructions, running, Float.toInt(totalSteps), tierCounts))

    | None => None
    }
    switch parsed {
    | Some((pc, stack, memory, instructions, running, totalSteps, tierCounts)) => (
        {
          ...model,
          vmInspector: {
            ...vm,
            pc: pc,
            stack: stack,
            memory: memory,
            instructions: instructions,
            running: running,
            totalSteps: totalSteps,
            tierCounts: tierCounts,
            loading: false,
            error: None,
          },
        },
        Tea_Cmd.none,
      )
    | None => ({...model, vmInspector: {...vm, loading: false, error: None}}, Tea_Cmd.none)
    }
  }
  | VmStateReceived(Error(err)) => (
      {...model, vmInspector: {...vm, loading: false, error: Some(err)}},
      Tea_Cmd.none,
    )
  | StepForward => {
      let cmd = if vm.bojRouting {
        BojCmd.invokeCartridgeWithLatency("dap-mcp", "step_forward", "", result => VmInspector(StepResult(result)), (c, t, e) => RecordBojLatency(c, t, e))
      } else {
        VmInspectorCmd.stepForward(result => VmInspector(StepResult(result)))
      }
      ({...model, vmInspector: {...vm, loading: true}}, cmd)
    }
  | StepBackward => {
      let cmd = if vm.bojRouting {
        BojCmd.invokeCartridgeWithLatency("dap-mcp", "step_backward", "", result => VmInspector(StepResult(result)), (c, t, e) => RecordBojLatency(c, t, e))
      } else {
        VmInspectorCmd.stepBackward(result => VmInspector(StepResult(result)))
      }
      ({...model, vmInspector: {...vm, loading: true}}, cmd)
    }
  | StepResult(Ok(jsonStr)) => {
      let parsed = switch Decoders.decodeOption(Tea_Json.value, jsonStr) {
      | Some(json) =>

        let obj = json->JSON.Decode.object->Option.getOr(Dict.make())
        let pc = obj->Dict.get("pc")->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0)
        let stackArr = obj->Dict.get("stack")->Option.flatMap(JSON.Decode.array)->Option.getOr([])
        let stack = stackArr->Array.filterMap(v => v->JSON.Decode.float->Option.map(Float.toInt))
        let memArr = obj->Dict.get("memory")->Option.flatMap(JSON.Decode.array)->Option.getOr([])
        let memory = memArr->Array.filterMap(m => {
          let mObj = m->JSON.Decode.object->Option.getOr(Dict.make())
          let address = mObj->Dict.get("address")->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0)
          let value = mObj->Dict.get("value")->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0)
          let recentRead = mObj->Dict.get("recentRead")->Option.flatMap(JSON.Decode.bool)->Option.getOr(false)
          let recentWrite = mObj->Dict.get("recentWrite")->Option.flatMap(JSON.Decode.bool)->Option.getOr(false)
          Some({
            VmInspectorModel.address: Float.toInt(address),
            value: Float.toInt(value),
            recentRead: recentRead,
            recentWrite: recentWrite,
          })
        })
        let instrMnemonic = obj->Dict.get("instructionMnemonic")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
        let running = obj->Dict.get("running")->Option.flatMap(JSON.Decode.bool)->Option.getOr(false)
        let totalSteps = obj->Dict.get("totalSteps")->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0)
        let tierCountsArr = obj->Dict.get("tierCounts")->Option.flatMap(JSON.Decode.array)->Option.getOr([])
        let tierCounts = tierCountsArr->Array.filterMap(v => v->JSON.Decode.float->Option.map(Float.toInt))
        Some((Float.toInt(pc), stack, memory, instrMnemonic, running, Float.toInt(totalSteps), tierCounts))

      | None => None
      }
      switch parsed {
      | Some((pc, stack, memory, instrMnemonic, running, totalSteps, tierCounts)) => {
          let newStep = totalSteps
          let snapshot: VmInspectorModel.vmSnapshot = {
            step: newStep,
            pc: pc,
            stack: stack,
            memory: memory,
            instructionMnemonic: instrMnemonic,
          }
          let history = Array.concat(vm.history, [snapshot])
          let trimmed = if Array.length(history) > 10000 {
            Array.sliceToEnd(history, ~start=Array.length(history) - 10000)
          } else {
            history
          }
          (
            {
              ...model,
              vmInspector: {
                ...vm,
                pc: pc,
                stack: stack,
                memory: memory,
                running: running,
                totalSteps: newStep,
                tierCounts: tierCounts,
                history: trimmed,
                timelinePosition: Array.length(trimmed) - 1,
                loading: false,
                error: None,
              },
            },
            Tea_Cmd.none,
          )
        }
      | None => {
          let newStep = vm.totalSteps + 1
          ({...model, vmInspector: {...vm, loading: false, totalSteps: newStep, error: None}}, Tea_Cmd.none)
        }
      }
    }
  | StepResult(Error(err)) => (
      {...model, vmInspector: {...vm, loading: false, error: Some(err)}},
      Tea_Cmd.none,
    )
  | RunVm => {
      let cmd = if vm.bojRouting {
        BojCmd.invokeCartridgeWithLatency("dap-mcp", "run", "", result => VmInspector(RunResult(result)), (c, t, e) => RecordBojLatency(c, t, e))
      } else {
        VmInspectorCmd.runToBreakpoint(result => VmInspector(RunResult(result)))
      }
      ({...model, vmInspector: {...vm, running: true}}, cmd)
    }
  | PauseVm => ({...model, vmInspector: {...vm, running: false}}, Tea_Cmd.none)
  | RunResult(Ok(jsonStr)) => {
    let parsed = switch Decoders.decodeOption(Tea_Json.value, jsonStr) {
    | Some(json) =>

      let obj = json->JSON.Decode.object->Option.getOr(Dict.make())
      let pc = obj->Dict.get("pc")->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0)
      let stackArr = obj->Dict.get("stack")->Option.flatMap(JSON.Decode.array)->Option.getOr([])
      let stack = stackArr->Array.filterMap(v => v->JSON.Decode.float->Option.map(Float.toInt))
      let memArr = obj->Dict.get("memory")->Option.flatMap(JSON.Decode.array)->Option.getOr([])
      let memory = memArr->Array.filterMap(m => {
        let mObj = m->JSON.Decode.object->Option.getOr(Dict.make())
        let address = mObj->Dict.get("address")->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0)
        let value = mObj->Dict.get("value")->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0)
        let recentRead = mObj->Dict.get("recentRead")->Option.flatMap(JSON.Decode.bool)->Option.getOr(false)
        let recentWrite = mObj->Dict.get("recentWrite")->Option.flatMap(JSON.Decode.bool)->Option.getOr(false)
        Some({
          VmInspectorModel.address: Float.toInt(address),
          value: Float.toInt(value),
          recentRead: recentRead,
          recentWrite: recentWrite,
        })
      })
      let totalSteps = obj->Dict.get("totalSteps")->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0)
      let tierCountsArr = obj->Dict.get("tierCounts")->Option.flatMap(JSON.Decode.array)->Option.getOr([])
      let tierCounts = tierCountsArr->Array.filterMap(v => v->JSON.Decode.float->Option.map(Float.toInt))
      Some((Float.toInt(pc), stack, memory, Float.toInt(totalSteps), tierCounts))

    | None => None
    }
    switch parsed {
    | Some((pc, stack, memory, totalSteps, tierCounts)) => (
        {
          ...model,
          vmInspector: {
            ...vm,
            pc: pc,
            stack: stack,
            memory: memory,
            totalSteps: totalSteps,
            tierCounts: tierCounts,
            running: false,
            error: None,
          },
        },
        Tea_Cmd.none,
      )
    | None => ({...model, vmInspector: {...vm, running: false, error: None}}, Tea_Cmd.none)
    }
  }
  | RunResult(Error(err)) => (
      {...model, vmInspector: {...vm, running: false, error: Some(err)}},
      Tea_Cmd.none,
    )
  | ResetVm => (
      {
        ...model,
        vmInspector: {
          ...vm,
          pc: 0,
          stack: [],
          history: [],
          timelinePosition: 0,
          totalSteps: 0,
          running: false,
          portLog: [],
          tierCounts: [0, 0, 0, 0, 0],
        },
      },
      Tea_Cmd.none,
    )
  | ToggleBreakpoint(idx) => {
      let hasIt = Array.some(vm.breakpoints, bp =>
        switch bp {
        | BreakAtInstruction(i) => i === idx
        | _ => false
        }
      )
      let newBps = if hasIt {
        Array.filter(vm.breakpoints, bp =>
          switch bp {
          | BreakAtInstruction(i) => i !== idx
          | _ => true
          }
        )
      } else {
        Array.concat(vm.breakpoints, [BreakAtInstruction(idx)])
      }
      let newInstructions = Array.map(vm.instructions, instr =>
        if instr.index === idx {
          {...instr, hasBreakpoint: !instr.hasBreakpoint}
        } else {
          instr
        }
      )
      (
        {...model, vmInspector: {...vm, breakpoints: newBps, instructions: newInstructions}},
        Tea_Cmd.none,
      )
    }
  | SeekTimeline(pos) => {
      let maxPos = Array.length(vm.history) - 1
      let clamped = if pos < 0 { 0 } else if pos > maxPos { maxPos } else { pos }
      ({...model, vmInspector: {...vm, timelinePosition: clamped}}, Tea_Cmd.none)
    }
  | ExportSnapshot => (
      model,
      VmInspectorCmd.exportSnapshot(result => VmInspector(SnapshotExported(result))),
    )
  | SnapshotExported(Ok(_)) => (model, Tea_Cmd.none)
  | SnapshotExported(Error(err)) => (
      {...model, vmInspector: {...vm, error: Some(err)}},
      Tea_Cmd.none,
    )
  | ToggleMultiVm => (
      {...model, vmInspector: {...vm, multiVmView: !vm.multiVmView}},
      Tea_Cmd.none,
    )
  | DismissVmError => ({...model, vmInspector: {...vm, error: None}}, Tea_Cmd.none)
  | ToggleVmBojRouting => ({...model, vmInspector: {...vm, bojRouting: !vm.bojRouting}}, Tea_Cmd.none)
  | TypeCheckResult(Ok(json)) => {
      let checks = model.typell.panelTypeChecks
      Dict.set(checks, "vminspector", json)
      let newTypell = {...model.typell, queriesServed: model.typell.queriesServed + 1, panelTypeChecks: checks}
      ({...model, typell: newTypell}, Tea_Cmd.none)
    }
  | TypeCheckResult(Error(_)) =>
    // TypeLL unavailable — degrade gracefully
    (model, Tea_Cmd.none)
  }
}
