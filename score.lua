local M = {}

--- creates a new file called "save.txt" with best score 0
-- should only be run once in an installation
local function createNewBest()
  local path = system.pathForFile( "save.txt", system.DocumentsDirectory)
  local file, errorString = io.open(path, "w")
  if not file then
    print("File error: "..errorString)
  end
  file:write("0")
  io.close(file)
  file = nil
end
M.createNewBest = createNewBest

--- gets the current best score
-- if the file doesn't exist, creates one and returns 0
local function getCurBest()
  local path = system.pathForFile("save.txt", system.DocumentsDirectory)
  local file, errorString = io.open(path, "r")
  local contents
  if not file then
    createNewBest()
  else
    contents = file:read("*a")
    io.close(file)
    return contents
  end
  file = nil
end
M.getCurBest = getCurBest

--- updates the file with a new score if it is higher than the current
-- @param newScore should be an integer
local function updateBest(newScore)
  local curBestScore = tonumber(getCurBest())
  local path = system.pathForFile("save.txt", system.DocumentsDirectory)
  if curBestScore < newScore then
    local file, errorString = io.open( path, "w" )
    if not file then
      print("File error: "..errorString)
    else
      file:write(newScore)
      io.close(file)
    end
    file = nil
  end
end
M.updateBest = updateBest

return M
