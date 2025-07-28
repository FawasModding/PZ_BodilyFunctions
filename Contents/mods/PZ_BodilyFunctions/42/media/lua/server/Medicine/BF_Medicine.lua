function OnEat_AntiDiarrhealPill(food, player, percent)
    local bowelsMaxValue = BF.GetMaxBowelValue()
    local currentBowels = BF.GetDefecateValue()
    local reduction = bowelsMaxValue * 0.1 * percent -- Reduce bowel value by 10% of max per pill
    BF.SetDefecateValue(math.max(0, currentBowels - reduction))
    print("Anti-Diarrheal Pill consumed: Bowel value reduced by " .. reduction)
end

function OnEat_LaxativePill(food, player, percent)
    local bowelsMaxValue = BF.GetMaxBowelValue()
    local currentBowels = BF.GetDefecateValue()
    local increase = bowelsMaxValue * 0.2 * percent -- Increase bowel value by 20% of max per pill
    BF.SetDefecateValue(math.min(bowelsMaxValue, currentBowels + increase))
    print("Laxative Pill consumed: Bowel value increased by " .. increase)
end

function OnEat_DiureticPill(food, player, percent)
    local bladderMaxValue = BF.GetMaxBladderValue()
    local currentBladder = BF.GetUrinateValue()
    local increase = bladderMaxValue * 0.2 * percent -- Increase bladder value by 20% of max per pill
    BF.SetUrinateValue(math.min(bladderMaxValue, currentBladder + increase))
    print("Diuretic Pill consumed: Bladder value increased by " .. increase)
end

function OnEat_AnticholinergicPill(food, player, percent)
    local bladderMaxValue = BF.GetMaxBladderValue()
    local currentBladder = BF.GetUrinateValue()
    local reduction = bladderMaxValue * 0.1 * percent -- Reduce bladder value by 10% of max per pill
    BF.SetUrinateValue(math.max(0, currentBladder - reduction))
    print("Anticholinergic Pill consumed: Bladder value reduced by " .. reduction)
end