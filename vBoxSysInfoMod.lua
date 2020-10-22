local os_clock = os.clock
local Wait = function(ms)
	local nTime = os_clock()+ms*.001
	repeat until os_clock() >= nTime
end



local os_getenv = os.getenv
local OS, UserName = (os_getenv("OS") or "Unknown"), (os_getenv("USERNAME") or "Unknown")
local Title, PreInitMsg = "vBoxSysInfoMod - VirtualBox VM System Information Modifier Lua v1 by JayMontana36", {
	"",
	"",
	"Hello "..UserName.." on "..OS..", I am vBoxSysInfoModLua (also known as VirtualBox VM System Information Modifier Lua),",
	"and I am both originally created and maintained by JayMontana36. Also, just as an additional and preemptive heads up:",
	"",
	"",
	"This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License.",
	"To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/4.0/ or",
	"send a letter to Creative Commons, PO Box 1866, Mountain View, CA 94042, USA.",
	"",
	"",
	"One final note, I am donationware; if you find and/or consider me to be useful, please consider donating to JayMontana36",
	'to help support further development (updates, functionality and features). See "Donate" for more information; thanks.',
	"",
	"",
}
local os_execute, print, io_read, io_open, io_close
	= os.execute, print, io.read, io.open, io.close
local vBoxPath, RunningOnWindows = "VBoxManage"
local function Init()
	if OS == "Windows_NT" then
		RunningOnWindows = true
		os_execute("title "..Title.." && cls")
	else
		RunningOnWindows = false
		os_execute("clear")
	end
	for i=1, #PreInitMsg do
		--Wait(250)
		print(PreInitMsg[i])
	end
	Wait(2500) print("Press Any Key To Continue...") io_read()
	if RunningOnWindows then
		vBoxPath = (os_getenv("VBOX_MSI_INSTALL_PATH") or "")
		
		local vBox = io_open(vBoxPath.."\VBoxManage.exe", "r")
		while not vBox do
			os_execute("cls")
			print("Failed to start "..Title)
			print()
			print("VirtualBox was not found in directory "..vBoxPath)
			print()
			print("Please provide the location of your current VirtualBox Installation:")
			vBoxPath = (io_read() or "") vBox = io_open(vBoxPath.."\VBoxManage.exe", "r")
		end
		io_close(vBox)
		vBoxPath = '"'..vBoxPath.."\VBoxManage.exe"..'"'
	end
end
local function ClearTerm()
	if RunningOnWindows then
		os_execute("cls")
	else
		os_execute("clear")
	end
	print(Title)
	print()
end



local string_gmatch = string.gmatch
local function Split(inputstr, sep)
	if sep == nil then sep = "%s" end local t,i={},0
	for str in string_gmatch(inputstr, "([^"..sep.."]+)") do
		i=i+1 t[i]=str
	end
return t end
local io_popen, string_find
	= io.popen, string.find
local ModesOfVM = {
	['"BIOS"'] = "pcibios",
	['"EFI"'] = "efi",
}
local VM = {
	Name,
	Mode,
	NewInfo = {
		Vendor,
		Product,
		Date
	},
	Functions = {
		Windows = {
			ListAndSelect = function()
				ClearTerm() VM.Name, VM.Mode = nil, nil
				print("A list of all available VirtualBox VMs:")
				local vBox = io_popen('"'..vBoxPath..' list vms'..'"') local ListOfVMs = vBox:read("*a") vBox:close() print(ListOfVMs)
				print()
				print("Name Of The (VirtualBox) VM To modify:")
				VM.Name = (io_read() or "")
				vBox = io_popen('"'..vBoxPath..' showvminfo "'..VM.Name..'" --machinereadable'..'"') local InfoFromVM = vBox:read("*a") vBox:close()
				
				for line in string_gmatch(InfoFromVM, '[^\r\n]+') do
					if string_find(line, "firmware") then
						VM.Mode = Split(line, "=")[2] break
					end
				end
				if not VM.Mode then VM.Name, VM.Mode = nil, nil return end
			end,
			Shutdown = function()
				os_execute('""'..vBoxPath..'" controlvm "'..VM.Name..'" poweroff'..'"')
			end,
			Modify = function()
				ClearTerm()
				local NameOfVM, ModeOfVM, Vendor, Product, Date = VM.Name, ModesOfVM[VM.Mode], VM.NewInfo.Vendor, VM.NewInfo.Product, VM.NewInfo.Date
				print('Suppressing VM Indications in TaskManager and other areas for "'..NameOfVM..'"\n...')
				os_execute('"'..vBoxPath..' modifyvm "'..NameOfVM..'" --paravirtprovider none'..'"')
				print("Applying System Information to vBox "..NameOfVM.." in "..ModeOfVM.." Mode.\n...")
				os_execute('"'..vBoxPath..' setextradata "'..NameOfVM..'" "VBoxInternal/Devices/'..ModeOfVM..'/0/Config/DmiSystemVendor" "'..Vendor..'"'..'"')
			end,
		},
		Unix = {
			
		}
	}
}



local function CollectNewinfoVM()
	ClearTerm()
	print("Name Of The (VirtualBox) VM To modify:\n"..VM.Name)
	print()
	print("System Vendor (Dell, ASUS, Lenovo, ASRock, MSI, etc) to assign:")
	VM.NewInfo.Vendor = (io_read() or "")
	print()
	print("Vendor Product (Optiplex 745, Rog 8, Optiplex GX620, etc):")
	VM.NewInfo.Product = (io_read() or "")
	print()
	print("BIOS/System Build Date (in M/D/YYYY or MM/DD/YYYY):")
	VM.NewInfo.Date = (io_read() or "")
end



local function TaskSummary()
	ClearTerm()
	print("Summary:")
	print("Ready to modify vBox VM "..VM.Name.." whenever you're ready.")
	print(VM.Mode..' Information will be changed to "'..VM.NewInfo.Vendor..' '..VM.NewInfo.Product..'"')
	print(VM.Mode..' Date will be changed to "'..VM.NewInfo.Date..'"')
	print()
	print("Warning: Before continuing, please shutdown any/all vBox VMs you care about;")
	print("failure to do so may result in data loss or data corruption for running VMs.")
	print("Press Any Key To Continue...") io_read()
end



local function Run()
	Init()
	local Functions if RunningOnWindows then Functions = VM.Functions.Windows else Functions = VM.Functions.Unix end
	while not VM.Name or not VM.Mode do
		Functions.ListAndSelect()
	end
	CollectNewinfoVM()
	TaskSummary()
	Functions.Shutdown()
	Functions.Modify()
end Run()