local M = {}

local function isOutOfBounds(minX, maxX, minY, maxY, objList)
  local isOOB = false
  for i = 1, table.getn(objList) do
    if  (objList[i].x < minX or objList[i].x > maxX or objList[i].y < minY or objList[i].y > maxY) then
      isOOB = true
    else
      return false
    end
  end
  return isOOB
end
M.isOutOfBounds = isOutOfBounds

return M
