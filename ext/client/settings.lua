-- UI/Flow/Graph/Options/OptionsGraph
local OptionsGraph = {
	Partition = Guid('840E40BB-9292-11E0-BF2A-F47BB751820F'),
	Asset = Guid('0DBC1B29-5F41-B00B-86DF-95642499AA5B'),
}

-- UI/Flow/Screen/OptionsControlsScreen
local ControlOptions = {
	Partition = Guid('ABDAF02F-D200-11DF-994F-B62E5E28B66C'),
	TabWidget = Guid('94E947B3-740F-48E1-B169-8B34D73DC72E'),
}

-- UI/Flow/Screen/OptionsVideoScreen
local VideoOptions = {
	Partition = Guid('E60401BF-D200-11DF-994F-B62E5E28B66C'),
	TabWidget = Guid('38EAD09C-8554-4A19-B34D-7686A9A0C8CA'),
}

-- UI/Flow/Screen/OptionsAudioScreen
local AudioOptions = {
	Partition = Guid('D740B5BF-D200-11DF-994F-B62E5E28B66C'),
	TabWidget = Guid('904F2189-46BB-48BC-B653-ADA83DF7D9B4'),
}

-- UI/Flow/Screen/OptionsGameplayScreen
local GameplayOptions = {
	Partition = Guid('BD4D087F-D200-11DF-994F-B62E5E28B66C'),
	TabWidget = Guid('1092D407-96BC-4F9A-88F6-DABB4FF0AE2F'),
}

-- UI/Flow/Screen/OptionsKeyBindingScreen
local KeyBindingOptions = {
	Partition = Guid('7D770D0D-0083-4805-9DEA-44D7E5E98534'),
	TabWidget = Guid('A55E4250-AA02-4674-B130-9108BC950842'),
}

local AllOptions = {
	ControlOptions,
	VideoOptions,
	AudioOptions,
	GameplayOptions,
	KeyBindingOptions,
}

local CustomOptionsStateNodeGuid = MathUtils:RandomGuid()

local function createEmptyPort(name)
	local port = UINodePort(MathUtils:RandomGuid())

	if name ~= nil then
		port.name = name
	end

	port.query = UIWidgetEventID.UIWidgetEventID_None
	port.allowManualRemove = false

	return port
end

local function patchOptionsGraphAsset(instance)
	local asset = UIGraphAsset(instance)
	asset:MakeWritable()

	local tabComparisonNode = nil

	-- Check if we already have our custom settings.
	for _, node in pairs(asset.nodes) do
		-- It's already here. We don't need to do anything.
		if node.instanceGuid == CustomOptionsStateNodeGuid then
			return
		elseif node:Is('ComparisonLogicNode') then
			local comparisonNode = ComparisonLogicNode(node)

			if comparisonNode.name == 'TabComparison' then
				tabComparisonNode = comparisonNode
				tabComparisonNode:MakeWritable()
			end
		end
	end

	local stateNode = DialogNode(CustomOptionsStateNodeGuid)
	stateNode.name = 'VuOptionsConfirmationDialog'
	stateNode.isRootNode = false
	stateNode.parentGraph = asset
	stateNode.parentIsScreen = false
	stateNode.inValue = createEmptyPort()
	stateNode.show = createEmptyPort('Show')
	stateNode.hide = createEmptyPort('Hide')
	stateNode.renderToTexture = false
	stateNode.dialogTitle = 'Settings applied'
	stateNode.dialogText = 'The changes you made to your VU settings have been applied!'
	stateNode.outputs:add(createEmptyPort('PopupButtonReleased'))

	local popupAsset = ResourceManager:SearchForDataContainer('UI/Flow/Screen/Popups/PopupGeneric')

	if popupAsset == nil then
		-- If the popup screen asset is not loaded yet we register
		-- a load handler that will be called once after it's loaded
		-- and assign it to the [screen] property.
		ResourceManager:RegisterInstanceLoadHandlerOnce(Guid('6609DF6B-E5CD-11DF-938F-855C96D24F62'), Guid('283B6A4B-B9FE-B798-9922-C35388C4DF40'), function(instance)
			stateNode.screen = UIScreenAsset(instance)
		end)
	else
		stateNode.screen = UIScreenAsset(popupAsset)
	end

	local okButton = UIPopupButton()
	okButton.inputConcept = UIInputAction.UIInputAction_OK
	okButton.label = 'OK'

	stateNode.buttons:add(okButton)

	-- This will show our popup when the user clicks on the VU Options tab (tab 6 / ID5).
	local tabNode = createEmptyPort('ID5')
	tabNode.allowManualRemove = true

	tabComparisonNode.outputs:add(tabNode)

	local tabComparisonConnection = UINodeConnection(MathUtils:RandomGuid())
	tabComparisonConnection.sourceNode = tabComparisonNode
	tabComparisonConnection.targetNode = stateNode
	tabComparisonConnection.sourcePort = tabNode
	tabComparisonConnection.targetPort = stateNode.inValue

	-- This will close the popup and return to tab0 when user clicks "OK" in the popup.
	local popupConnection = UINodeConnection(MathUtils:RandomGuid())
	popupConnection.sourceNode = stateNode
	popupConnection.targetNode = DataSetNode(ResourceManager:SearchForInstanceByGuid(Guid('1747E0E5-8370-448A-A229-96D64649C228')))
	popupConnection.sourcePort = stateNode.outputs[1]
	popupConnection.targetPort = DataSetNode(popupConnection.targetNode).inValue
	popupConnection.numScreensToPop = 1

	asset.nodes:add(stateNode)
	asset.connections:add(tabComparisonConnection)
	asset.connections:add(popupConnection)
end

local function patchTabWidget(instance)
	local widget = WidgetNode(instance)
	widget:MakeWritable()

	-- Check if we already have a tabs property.
	for _, property in pairs(widget.widgetProperties) do
		-- If we do and the value is not empty then there's nothing to do.
		if property.name == 'Tabs' and #property.value > 0 then
			return
		end
	end

	local tabsProperty = UIWidgetProperty()
	tabsProperty.name = 'Tabs'
	tabsProperty.value = 'ID_M_CONTROLS;ID_M_GAMEPLAY;ID_M_AUDIO;ID_M_VIDEO;ID_M_OPTIONS_KEY_BINDINGS;VU OPTIONS'

	widget.widgetProperties:add(tabsProperty)
end

Events:Subscribe('Extension:Loaded', function()
	ResourceManager:RegisterInstanceLoadHandler(OptionsGraph.Partition, OptionsGraph.Asset, function(instance)
		patchOptionsGraphAsset(instance)
	end)

	local optionsGraphAsset = ResourceManager:FindInstanceByGuid(OptionsGraph.Partition, OptionsGraph.Asset)

	if optionsGraphAsset ~= nil then
		patchOptionsGraphAsset(optionsGraphAsset)
	end

	for _, lookupData in pairs(AllOptions) do
		ResourceManager:RegisterInstanceLoadHandler(lookupData.Partition, lookupData.TabWidget, function(instance)
			patchTabWidget(instance)
		end)

		local tabWidget = ResourceManager:FindInstanceByGuid(lookupData.Partition, lookupData.TabWidget)

		if tabWidget ~= nil then
			patchTabWidget(tabWidget)
		end
	end
end)

Hooks:Install('UI:PushScreen', 1, function(hook, screen, priority, parentGraph, stateNodeGuid)
	--print('Pushing screen')
	--print(stateNodeGuid)

	if stateNodeGuid == CustomOptionsStateNodeGuid then
		--print('Opened custom settings')
		WebUI:ExecuteJS('DispatchAction(actions.SHOW_SETTINGS_POPUP, { show: true });')
	end
end)
