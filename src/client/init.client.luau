--!strict
local HudController = require(script:WaitForChild("controllers"):WaitForChild("HudController"))
HudController.Start()
local ShopController = require(script:WaitForChild("controllers"):WaitForChild("ShopController"))
task.spawn(ShopController.Start)
task.spawn(require(script.controllers.PetController).Start)
task.spawn(require(script.controllers.PetFollowController).Start)
