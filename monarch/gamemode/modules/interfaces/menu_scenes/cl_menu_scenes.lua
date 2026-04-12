

local MenuScenes = {}
MenuScenes.currentScene = 1
MenuScenes.sceneTransitionTime = 0
MenuScenes.sceneDuration = 8  
MenuScenes.transitionDuration = 1.5  
MenuScenes.fadeAlpha = 0
MenuScenes.isFading = false
MenuScenes.cachedPos = nil
MenuScenes.cachedAng = nil

MenuScenes.scenes = {
    {
        name = "Scene 1",
        startPos = Vector(0, 0, 100),
        startAng = Angle(0, 0, 0),
        endPos = Vector(500, 200, 150),
        endAng = Angle(10, 45, 0),
        duration = 8,
    },
    {
        name = "Scene 2",
        startPos = Vector(500, 200, 150),
        startAng = Angle(10, 45, 0),
        endPos = Vector(-300, 400, 120),
        endAng = Angle(5, 180, 0),
        duration = 8,
    },
    {
        name = "Scene 3",
        startPos = Vector(-300, 400, 120),
        startAng = Angle(5, 180, 0),
        endPos = Vector(200, -250, 140),
        endAng = Angle(15, 270, 0),
        duration = 8,
    },
}

function MenuScenes:Initialize()
    self.currentScene = 1
    self.sceneTransitionTime = 0
    self.fadeAlpha = 0
    self.isFading = false
    self:RecalculateCamera()
end

function MenuScenes:RecalculateCamera()
    local scene = self.scenes[self.currentScene]
    if not scene then
        self.cachedPos = Config.BackDropCoord or Vector(0, 0, 0)
        self.cachedAng = Config.BackDropAngs or Angle(0, 0, 0)
        return
    end

    local duration = tonumber(scene.duration) or 0
    if duration <= 0 then duration = 0.001 end

    local progress = math.min(self.sceneTransitionTime / duration, 1)
    self.cachedPos = LerpVector(progress, scene.startPos, scene.endPos)
    self.cachedAng = LerpAngle(progress, scene.startAng, scene.endAng)
end

function MenuScenes:Update(deltaTime)
    local scene = self.scenes[self.currentScene]
    if not scene then return end

    self.sceneTransitionTime = self.sceneTransitionTime + deltaTime

    if self.sceneTransitionTime < self.transitionDuration then
        self.fadeAlpha = Lerp(
            self.sceneTransitionTime / self.transitionDuration,
            255,
            0
        )
        self.isFading = true
    else
        self.fadeAlpha = 0
        self.isFading = false
    end

    if self.sceneTransitionTime >= scene.duration then
        self:NextScene()
        return
    end

    self:RecalculateCamera()
end

function MenuScenes:NextScene()
    self.currentScene = self.currentScene + 1
    if self.currentScene > #self.scenes then
        self.currentScene = 1
    end
    self.sceneTransitionTime = 0
    self.fadeAlpha = 255  
    self:RecalculateCamera()
end

function MenuScenes:GetCameraView()
    if not self.cachedPos or not self.cachedAng then
        self:RecalculateCamera()
    end

    return self.cachedPos, self.cachedAng
end

function MenuScenes:DrawFadeOverlay()
    if self.fadeAlpha <= 0 then return end

    surface.SetDrawColor(0, 0, 0, self.fadeAlpha)
    surface.DrawRect(0, 0, ScrW(), ScrH())
end

function MenuScenes:GetSceneInfo()
    local scene = self.scenes[self.currentScene]
    if scene then
        return scene.name, self.currentScene, #self.scenes
    end
    return "Unknown", 0, 0
end

function LerpAngle(t, from, to)
    local result = Angle(0, 0, 0)
    result.p = Lerp(t, from.p, to.p)
    result.y = Lerp(t, from.y, to.y)
    result.r = Lerp(t, from.r, to.r)
    return result
end

if Monarch and Monarch.MenuScenes then
    MenuScenes.scenes = Monarch.MenuScenes
end

Monarch.MenuScenes = MenuScenes
