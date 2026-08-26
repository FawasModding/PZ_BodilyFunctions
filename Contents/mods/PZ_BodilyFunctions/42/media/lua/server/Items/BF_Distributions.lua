require 'Items/Distributions'
require 'Items/ProceduralDistributions'

local pills = {
    "BF.AntiDiarrhealPillBox",    2,
    "BF.LaxativePillBox",         2,
    "BF.DiureticPillBox",         2,
    "BF.AnticholinergicPillBox",  2,
}

-- nil guards protect against removed containers.
local function addPills(containerName)
    local container = ProceduralDistributions.list[containerName]
    if not container then return end
    for i = 1, #pills do
        table.insert(container.items, pills[i])
    end
end

addPills("BathroomCabinet")
addPills("BathroomCounter")
addPills("MedicalClinicDrugs")
addPills("MedicalStorageDrugs")
addPills("SafehouseMedical") -- For safehouse, may have weird things like bottled urine eventually.