define hook-stop
  set $special=($special | 1)
end

define hook-run
  set $special=($special & ~1)
end

define hook-continue
  set $special=($special & ~1)
end

define hookpost-remote
  monitor reset
  continue
end