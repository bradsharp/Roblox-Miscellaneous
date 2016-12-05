function clipIn(cf, dis)
	local render = game:GetService("RunService").RenderStepped
	camera.CameraType = "Scriptable"
	local a,b,c,d,e,f,g,h,i,j,k,l = cf:components()
	local x = dis
	repeat
		local t = render:wait()
		x = math.max(x - (t * 200), 1)
		local scale = 1 / x
		camera.CFrame = CFrame.new(a, b, c,
	        d*scale, e*scale, f*scale,
	        g*scale, h*scale, i*scale,
	        j*scale, k*scale, l*scale)
	until x == 1
end
