module(..., package.seeall)

--[[
 VERSION 1.2
 
 This version has been updated to work with Graphics 2.0
 
 Chris Norman - chris@inzi.com
 Nov. 12, 2013
 http://www.inzi.com



--]]


--[[

 Simple helper class that makes it possible to show text based output (like with the "print()" command) directly
 in your App and not in the console window. This is useful for using it on the device where no extra console
 window is available.
 Beside the possibility to show only white colored text, it is also possible to use special methods that give the text
 a specific color. This is useful to give the messages you write out to the console a weight just as with good old java
 loggers.

 The following methods for giving your text a weight are available

 error()   -> produces red text
 warning() -> produces yellow text
 info()    -> produces green text
 debug()   -> produces light blue text

 If you just want to print out white text and don't care about the weight of information, then you get the job done
 by using the print() method just like the regular lua print command that writes to the console window.


 Sample usage:

 Initialize an instance of this class as soon as possible. A good place to do so is your main.lua file

 << main.lua

  require("eventConsole")

  eventConsole = eventConsole:new()

  ...
 >>>>>>>>>>>>>>>

 That's all. The above code creates a small touchable button in the top center of the device screen, that always is
 kept on the top of all drawn display objects. If you click the button the first time, a half transparent scroll view
 with the log messages will become visible. If you click the button again, the scroll view will become invisible and
 so on.

 Now you have access to this instance everywhere in your code and you can use it like shown here:

 << yourFile.lua

  ...

  function object:checkFileExistence(fileName)
   local retVal = false
   local path   = system.pathForFile( fileName, self.baseDirectory )

   eventConsole:print("Checking file existence now...") -- writes a white colored text

   local file = io.open( path )

   if(file ~= nil) then

    eventConsole:info("File was found...") -- writes a green colored text of weight "info"
    io.close(file)
    retVal= true

   else

    eventConsole:error("File not found...") -- writes a red colored text of weight "error"

   end

   return retVal
  end
 >>>>>>>>>>>>>>>


 IMPORTANT:

 Once your App is ready for being published, you don't need to delete all the calls of the eventConsole instance
 everywhere in your code.
 The only thing you need to do in order to deactivate the console is adding the following line
 right after the creation of the instance in the main.lua file

 eventConsole:disable()

--]]




--[[
 author          : andreas ermrich
 author mail     : aeh@incowia.com
 company         : incowia GmbH / Garamox
 websites        : http://www.incowia.com
                   http://www.garamox.de

 version         : 1.0
 date            : 2012.07.12
 author comments : use it for free and enjoy. Please give me your feedback with a short mail!!!
]]--
function eventConsole:new()
    local CoronaWidget = require("widget")
    local object = {
                     numLogEntries   = 0                 ,
                     scrollView      = nil               ,
                     activator       = display.newGroup(),
                     consoleFontSize = 12 * ((display.contentHeight/30)/16)                ,
                     visible         = false             ,
                     disabled        = false             ,
                     toFrontThread   = nil
                   }

    --[[
     constructor
    ]]--
    function object:init()

        --create a scroll view that acts as container for all the log entries
        --self.scrollView           = CoronaWidget.newScrollView( {bgColor = {0,0,0,210}, scrollWidth = display.contentWidth, scrollHeight = display.contentHeight} )
        self.scrollView           = CoronaWidget.newScrollView{ 
            top = 0, 
            left = 0,
            width = display.contentWidth,
            height = display.contentHeight
        }


        self.scrollView.isVisible = false

        --the next elements are used as touchable display group for switching the visibility state of the scroll view
        local circle = display.newCircle(display.contentWidth/2, 1, display.contentWidth*.2) -- needed for better handling. By the help of this circle we don't need to exactly
        circle.x = display.contentWidth/2
        circle.y = 20
        circle.fill = {1,1,1,.25}                                                -- hit the smaller visible circle which is created next to trigger the touch event

        local circle2 = display.newCircle(display.contentWidth/2, 1, display.contentWidth*.05)
        circle2.x = display.contentWidth/2
        circle2.y = 20
        circle2:setFillColor(1,1,1)
        circle2:setStrokeColor(.8,.2,.2)
        circle2.strokeWidth=5
        circle2.fill={1,1,1,1}

        local caption = display.newText("C", 0, 0, native.systemFont,16 * ((display.contentHeight/30)/16) )--42*(display.contentHeight*.05))
        caption:setFillColor(0,0,.95)
        
        caption.x = display.contentWidth/2 --circle2.x --display.contentWidth/2 + 1
        caption.y = 20 --circle2.y

        self.activator:insert(circle)
        self.activator:insert(circle2)
        self.activator:insert(caption)
        self.activator:addEventListener("touch", self )

        --Closure that will be executed in a separate thread. Necessary to keep the console on top of the screen
        local cl = function()
                     self.scrollView:toFront()
                     self.activator:toFront()
                   end

        self.toFrontThread = timer.performWithDelay(10, cl, 0) --start the thread with an calling interval of 10 milliseconds
    end


    --[[
     This adds a new text without a color code
    ]]--
    function object:print(text)
        self:write(text, {0,0,0}, "")
    end


    --[[
     This adds a new text marked as error
    ]]--
    function object:error(text)
        self:write(text, {1,0,0}, "E")
    end


    --[[
     This adds a new text marked as warning
    ]]--
    function object:warning(text)
        self:write(text, {1,.9,.2}, "W")
    end


    --[[
     This adds a new text marked as info message
    ]]--
    function object:info(text)
        self:write(text, {0,1,0}, "I")
    end


    --[[
     This adds a new text marked as debug message
    ]]--
    function object:debug(text)
        self:write(text, {.6,.7,1}, "D")
    end


    --[[
     This adds a new text to the output scrollview
    ]]--
    function object:write(text, colorTable, typeMarker)
        if(self.disabled == true) then return end

            display.setDefault( "anchorX", 0 )
            display.setDefault( "anchorY", 0 )

        local text = display.newText(os.date("%Y/%m/%d  %H:%M:%S") .. " >" .. typeMarker .. "> " .. text, 0, self.numLogEntries * self.consoleFontSize, native.systemFont, self.consoleFontSize)

            display.setDefault( "anchorX", 0.5 )
            display.setDefault( "anchorY", 0.5 )
    
        print (text.x .. " : " .. text.y)

        text.x = display.contentCenterX * -1
        
        
        text:setFillColor(colorTable[1], colorTable[2], colorTable[3])

        self.scrollView:insert(text)
        
        text.y = text.y - display.contentCenterY
        
        self.numLogEntries = self.numLogEntries + 1
    end


    --[[
     Touch handler that switches the scroll view visibility state
    ]]--
    function object:touch(event)
        if(event.phase == "began") then
            self.visible              = not self.visible
            self.scrollView.isVisible = self.visible
        end
        return true
    end


    --[[
     deactivate this instance. Used when your code goes into productive phase
    ]]--
    function object:disable()
     self.disabled = true
     timer.cancel(self.toFrontThread) -- stop the thread that brings the scroll view and the touchable display group to the front
     display.remove(self.scrollView)
     display.remove(self.activator)
    end

    object:init()
    return object
end
