-- This software is copyright Kong Inc. and its licensors.
-- Use of the software is subject to the agreement between your organization
-- and Kong Inc. If there is no such agreement, use is governed by and
-- subject to the terms of the Kong Master Software License Agreement found
-- at https://konghq.com/enterprisesoftwarelicense/.
-- [ END OF LICENSE 0867164ffc95e54f04670b5169c09574bdbd9bba ]

local cjson = require("cjson")
local ngx = ngx


local ErrorHandlerLog = {}


ErrorHandlerLog.PRIORITY = 1000


local function register(phase)
  local ws_id = ngx.ctx.workspace or kong.default_workspace
  local phases = ngx.ctx.err_handler_log_phases or {}
  local in_ws = phases[ws_id] or {}
  phases[ws_id] = in_ws
  table.insert(in_ws, phase)
  ngx.ctx.err_handler_log_phases = phases
end


function ErrorHandlerLog:rewrite(conf)
  register("rewrite")
end


function ErrorHandlerLog:access(conf)
  register("access")
end


function ErrorHandlerLog:header_filter(conf)
  register("header_filter")

  local phases = ngx.ctx.err_handler_log_phases or {}


  ngx.header["Content-Length"] = nil
  ngx.header["Log-Plugin-Phases"] = table.concat(phases[ngx.ctx.workspace] or {}, ",")
  ngx.header["Log-Plugin-Workspaces"] = cjson.encode(phases)

  ngx.header["Log-Plugin-Service-Matched"] = ngx.ctx.service and ngx.ctx.service.name
end


function ErrorHandlerLog:body_filter(conf)
  if not ngx.arg[2] then
    ngx.arg[1] = "body_filter"
  end
end


return ErrorHandlerLog
