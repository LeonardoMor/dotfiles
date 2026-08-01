local function launch_or_focus(app)
  return function()
    local needle = app:lower()

    for _, window in ipairs(hl.get_windows()) do
      if window.initial_class:lower():find(needle, 1, true) then
        hl.dispatch(hl.dsp.focus({ window = window }))
        return
      end
    end

    hl.dispatch(hl.dsp.exec_cmd('gtk-launch ' .. app))
  end
end

hl.bind('SUPER + CTRL + ALT + T', launch_or_focus('com.mitchellh.ghostty'), { description = 'Ghostty' })
hl.bind('SUPER + G', launch_or_focus('steam'), { description = 'Steam' })
hl.bind('SUPER + CTRL + ALT + Z', launch_or_focus('zen'), { description = 'Zen Browser' })
hl.bind('SUPER + CTRL + ALT + D', launch_or_focus('discord'), { description = 'Discord' })

hl.bind('SUPER + Z', hl.dsp.workspace.toggle_special('first'), { description = 'Toggle first special workspace' })
hl.bind('SUPER + SHIFT + Z', hl.dsp.window.move({ workspace = 'special:first', follow = false }), { description = 'Move to first special workspace' })

hl.bind('SUPER + SHIFT + comma', hl.dsp.exec_cmd('dms ipc call notifications clearAll'), { description = 'Dismiss all notifications' })
hl.bind('SUPER + SHIFT + D', hl.dsp.exec_cmd('dms ipc call notifications toggleDoNotDisturb'), { description = 'Toggle do not disturb' })

hl.bind('CTRL + ALT + space', hl.dsp.exec_cmd('switch-layout'), { description = 'Switch keyboard layout' })
hl.bind('SUPER + SHIFT + A', hl.dsp.exec_cmd('dms ipc call audio cycleoutput'), { description = 'Switch audio output' })
