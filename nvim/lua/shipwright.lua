local function is_empty(s)
  return s == nil or s == ''
end

local function file_exists(filepath)
  if vim.fn.filereadable(filepath) ~= 1 then
    return false
  end
  return true
end

-- Returns if filepath was opened
local function open_if_exists(filepath)
  if not file_exists(filepath) then
    return false
  end

  vim.cmd('edit ' .. filepath)
  return true
end

-- Returns buffer content as comma seperated string
local function get_buffer_content()
  local buffer_content = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  return table.concat(buffer_content, ',')
end

local function get_chart_version_from_draft()
  local bufferContent = get_buffer_content()
  return string.match(bufferContent, 'chartVersion:%s*([%d.]+)')
end

-- Removes 'repo/' in 'repo/chartname' format
local function chartNameWithoutRepo(chartName)
  return string.match(chartName, '%S*/(%S*)')
end

-- Check for 'useHelmV3: true' in current buffer
local function is_helmv3()
  local buffer = get_buffer_content()
  -- Tricky comma at end of regex due to commas in get_buffer_content()
  local helmV3 = string.match(buffer, 'useHelmV3:%s*(%S*),?')
  return helmV3 == 'true'
end

local function get_default_helm_v2_version()
 -- Shipwright's current v2 default
  return '2.16.4'
end

local function get_default_helm_v3_version()
 -- Shipwright's current v3 default
 return '3.7.1'
end

local function get_helm_v3_override()
  local buffer = get_buffer_content()
  -- Look for 'helmV3VersionOverride: <<SemVer>>' in current buffer
  local overrideVersion = string.match(buffer, 'helmV3VersionOverride:%s*(%S*)')
  return overrideVersion
end

-- Get 'helmV2VersionOverride: <<SemVer>>' in current buffer
local function get_helm_v2_override()
  local buffer = get_buffer_content()
  local overrideVersion = string.match(buffer, 'helmV2VersionOverride:%s*(%S*)')
  return overrideVersion
end

-- Finds the helm version which would have fetched this chart
local function get_chart_helm_version()

  if is_helmv3() then
    local v3_override = get_helm_v3_override()
    if is_empty(v3_override) then
      return get_default_helm_v3_version()
    else
      return v3_override
    end
  end

  -- HelmV2
  local v2_override = get_helm_v2_override()
  if is_empty(v2_override) then
    return get_default_helm_v2_version()
  end
  return v2_override
end

local function handle_draft_gx()
  local line = vim.api.nvim_get_current_line()

  -- Get 'chartName: <<name>>' value
  local chartName = string.match(line, 'chartName:%s*(%S*)')
  if is_empty(chartName) then
    return
  end

  -- Look for locally defined chart, open and exit if found
  local localChartPath = 'helm-charts/'..chartName..'/Chart.yaml'
  if open_if_exists(localChartPath) then
    return
  end

  -- Get 'chartVersion: <<SemVer>>' value
  local chartVersion = get_chart_version_from_draft()
  if is_empty(chartVersion) then
    print('Could not obtain chartVersion')
    return
  end

  -- Look for locally defined chart with sub chartVersion, open and exit if found
  local localChartPathWithVersion = 'helm-charts/'..chartName..'/'..chartVersion..'/Chart.yaml'
  if open_if_exists(localChartPathWithVersion) then
    return
  end

  -- Look for local copy of remote chart, open and exit if found
  local chartHelmVersion = get_chart_helm_version()

  local remoteCopyPath = '.cache/helm-'..chartHelmVersion..'/charts/'..chartName..'-'..chartVersion..'/'..chartNameWithoutRepo(chartName)..'/Chart.yaml'

  if open_if_exists(remoteCopyPath) then
    return
  end

  print('Could not determine location of parent chart')
end

local function handle_blueprint_gx()
  local line = vim.api.nvim_get_current_line()

  -- Find parent draft and open if specified
  local draft = string.match(line, 'draft:%s*(%S*)')
  if not is_empty(draft) then
    local draftpath = 'drafts/' .. draft .. '/draft.yaml'
    if open_if_exists(draftpath) then
      return
    end
  end

  local chart = string.match(line, 'chartName:%s*(%S*)')
  if is_empty(chart) then
    return
  end

  -- Find parent chart and open if specified
  local localChartPath = 'helm-charts/' .. chart .. '/chart.yaml'
  if open_if_exists(localChartPath) then
    return
  end

  -- Get 'chartVersion: <<SemVer>>' value
  local chartVersion = get_chart_version_from_draft()
  if is_empty(chartVersion) then
    print('Could not obtain chartVersion')
    return
  end

  -- Find parent chart with chartVersion and open if specified
  local localChartPathWithVersion = 'helm-charts/'..chart..'/'..chartVersion..'/Chart.yaml'
  if open_if_exists(localChartPathWithVersion) then
    return
  end

end

-- Override gx behavior
vim.keymap.set('n', 'gx', function()
  -- Get the name of the current file
  local file_name = vim.api.nvim_buf_get_name(0)

  if file_name:match("blueprint.yaml$") then
    handle_blueprint_gx()
  elseif file_name:match("draft.yaml$") then
    handle_draft_gx()
  else
    -- Default gx behavior
    vim.cmd("execute 'normal! gx'")
  end

end, { silent = true } )
