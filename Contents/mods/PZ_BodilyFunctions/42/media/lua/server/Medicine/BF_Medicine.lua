-- Pill amounts are in mL; Based on the average capacity rather than a specific character's.
-- A pill does the same amount no matter who's using it.

function OnEat_AntiDiarrhealPill(food, player, percent)
    local currentBowels = BF.GetDefecateValue()
    local reduction = BF.GetBaseBowelCapacity() * 0.1 * percent -- 10% of an average bowel per pill
    BF.SetDefecateValue(math.max(0, currentBowels - reduction))
    print("Anti-Diarrheal Pill consumed: Bowel value reduced by " .. reduction)
end

function OnEat_LaxativePill(food, player, percent)
    local bowelsMaxValue = BF.GetBowelCapacity(player)
    local currentBowels = BF.GetDefecateValue()
    local increase = BF.GetBaseBowelCapacity() * 0.2 * percent -- 20% of an average bowel per pill
    BF.SetDefecateValue(math.min(bowelsMaxValue, currentBowels + increase))
    print("Laxative Pill consumed: Bowel value increased by " .. increase)
end

function OnEat_DiureticPill(food, player, percent)
    local bladderMaxValue = BF.GetBladderCapacity(player)
    local currentBladder = BF.GetUrinateValue()
    local increase = BF.GetBaseBladderCapacity() * 0.2 * percent -- 20% of an average bladder per pill
    BF.SetUrinateValue(math.min(bladderMaxValue, currentBladder + increase))
    print("Diuretic Pill consumed: Bladder value increased by " .. increase)
end

function OnEat_AnticholinergicPill(food, player, percent)
    local currentBladder = BF.GetUrinateValue()
    local reduction = BF.GetBaseBladderCapacity() * 0.1 * percent -- 10% of an average bladder per pill
    BF.SetUrinateValue(math.max(0, currentBladder - reduction))
    print("Anticholinergic Pill consumed: Bladder value reduced by " .. reduction)
end