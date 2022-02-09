from psychopy import gui, visual, core, event, monitors, prefs
prefs.hardware['audioLib'] = ['ptb', 'pyo']
from psychopy.sound import Sound
from psychopy.event import waitKeys
import numpy as np
import os, time, random, math, csv
from TVStimuli import TVStimuli
from RotationMain import *

if __name__ == '__main__':
    TVStimuli.calibrate(os.path.join(os.getcwd(), 'Calibration', 'eccentricity_monitor_calibration.csv'))
    roll = FaceRoll()
    yaw = FaceYaw()
    pitch = FacePitch()
    rotations = ['r' + str(rolls) for rolls in roll.rotations] + \
        ['y' + str(yaws) for yaws in yaw.rotations] + ['p' + str(pitches) for pitches in pitch.rotations] 

class RotationDemo(TVStimuli):
    recordData = False
    numTimeOut = 0
    demoWait = 10
    demoMode = True
    winners = roll.winners
    highScores = roll.highScores
    
    trialsPerSet = 18
    numSets = 3
    initialPracticeTrials = 6
    trainingTime = 5
    trainingReps = 1
    postSetBreak = 5
    dummyTrials = 3
    
    trainingHeight = TVStimuli.angleCalc(TVStimuli.referenceSize) * float(TVStimuli.tvInfo['faceHeight'])
    trainingWidth = TVStimuli.angleCalc(TVStimuli.referenceSize) * float(TVStimuli.tvInfo['faceWidth'])
    
    def __init__(self):
        super().__init__(rotations, '', 'face')
    
    @staticmethod
    def showWait(seconds = -1, keys = ['space'], flip = True, demoWait = -1):
        if flip: TVStimuli.win.flip()
        if seconds < 0:
            key = waitKeys(keyList = keys + ['escape'], maxWait = demoWait if demoWait >= 0 else RotationDemo.demoWait)
            RotationDemo.demoMode = key == None
        else:
            key = waitKeys(keyList = ['escape'], maxWait = seconds)
        if key != None and key[0] == 'escape':
            core.quit()
    
    def showImage(self, displayImage, set, showTarget, rotation):
        rotation = str(rotation)
        if rotation[0] == 'r':
            roll.showImage(displayImage, set, showTarget, float(rotation[1:]))
        elif rotation[0] == 'y':
            yaw.showImage(displayImage, set, showTarget, float(rotation[1:]))
        elif rotation[0] == 'p':
            pitch.showImage(displayImage, set, showTarget, float(rotation[1:]))
        else:
            roll.showImage(displayImage, set, showTarget, float(rotation))
    
    def instructions(self):
        self.demo()

    def demo(self):
        self.displayImage.pos = (0,0)
        self.displayImage.size = (self.trainingWidth,self.trainingHeight)
        RotationDemo.demoWait = 1
        roll.demo()
        yaw.demo()
        pitch.demo()
    
    def showHighScores(self):
        return
    
    def learningPeriod(self, set):
        return
    
    def learningTrial(self, set, target, mapping, repeatText = False):
        return
    
    def practiceRound(self, set, practiceTrials = initialPracticeTrials, trialsLeft = 0):
        return
    
    def breakScreen(self, trialsLeft = 0):
        super().breakScreen(trialsLeft)
        self.demo()
    
    @staticmethod
    def genDisplay(text, xPos, yPos, height = 1.5, color = 'white'):
        TVStimuli.genDisplay(text, xPos/2, yPos/2, height = height/2, color = color)
    
    def stimTest(self, set, target, rotation, correctKey, practice = False):
        self.showCross(prePause = 0.2)
        self.showWait(random.randint(5,15)/10, flip = False)
        leftEdge, rightEdge = -float(self.tvInfo['leftEdge']), float(self.tvInfo['rightEdge'])
        self.displayImage.pos = (random.randint(int(leftEdge/3),int(rightEdge/3)), random.randint(-50,50)/10)
        scale = random.randint(25,100) / 100
        self.displayImage.size = (self.trainingWidth * scale,self.trainingHeight * scale)
        self.displayImage.ori = 0
        self.showImage(self.displayImage, set, target, rotation)
        result = {'start': 0, 'end': 0}
        self.win.timeOnFlip(result, 'start')
        self.win.flip()
        
        RotationDemo.demoMode = RotationDemo.demoMode or self.numTimeOut > 3
        waitTime = self.timeOut
        if RotationDemo.demoMode: waitTime = min(waitTime, random.randint(1000, 1250)/1000)
        keys = event.waitKeys(timeStamped = True, maxWait = waitTime + float(self.tvInfo['timeDelay'])/1000)
        if keys == None:
            if RotationDemo.demoMode and waitTime != self.timeOut:
                response = correctKey if random.randint(0,9) < 8 else 'wrong'
                result['end'] = result['start'] + waitTime + float(self.tvInfo['timeDelay'])/1000
            else:
                response = 'timedOut'
                result['end'] = result['start']
                self.numTimeOut += 1
        else:
            response = keys[0][0]
            result['end'] = keys[0][1]
            self.numTimeOut = 0
            RotationDemo.demoMode = False
        self.win.flip()
        
        if response == 'escape':
            core.quit()
        reactionTime = (result['end'] - result['start']) * 1000 - float(self.tvInfo['timeDelay'])
        if response == correctKey:
            self.feedback(True, scoreChange = (not practice) * (min(self.timeOut * 1000 - reactionTime, 800)/2 + 600))
        elif response == 'timedOut':
            self.feedback(-1, scoreChange = (not practice) * -400)
        else:
            self.feedback(False, scoreChange = (not practice) * -min(reactionTime, 800)/2)
        return [(response == correctKey) * 1, rotation, reactionTime, set * 3 + target]

if __name__ == '__main__':
    roll.showWait = RotationDemo.showWait
    yaw.showWait = RotationDemo.showWait
    pitch.showWait = RotationDemo.showWait
    while True:
        RotationDemo().main()