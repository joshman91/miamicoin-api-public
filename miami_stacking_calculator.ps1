Clear-Host

    # "amount" in hex = "616D6F756E74"
    # "amountToken" = 616D6F756E74546F6B656E
    # "amountUstx" =  616D6F756E7455737478

function getMiaStackStats {
    Param([string]$sender_address, [int]$myStack, [int]$cycle_dec)

    #Get STX Prices
    $req_stxusd = Invoke-RestMethod -Uri "https://www.okcoin.com/api/spot/v3/instruments/STX-USD/ticker"
    $price_stxusd = [float]$req_stxusd.last
    $req_stxbtc = Invoke-RestMethod -Uri "https://www.okcoin.com/api/spot/v3/instruments/STX-BTC/ticker"
    $price_stxbtc = [float]$req_stxbtc.last

    $uri = "https://stacks-node-api.mainnet.stacks.co/v2/contracts/call-read/SP466FNC0P7JWTNM2R9T199QRZN1MYEDTAR0KP27/miamicoin-core-v1/get-stacking-stats-at-cycle"

    $cycle_hex = "0x010000000000000000000000000000000" + "{0:X}" -f $cycle_dec

    $body = @{}
    $body.Add("sender", $sender_address)
    $body.Add("arguments", @($cycle_hex))
    $body = $body | ConvertTo-Json -Depth 4

    $req = Invoke-RestMethod -Uri $uri -Method Post -Body $body -ContentType "application/json"
    $result = $req.result


    #GET TOTAL MIA STACKED
    $amountToken_start = $result.Substring(64)
    $amountToken_end = $amountToken_start.Split("0a")[0]
    $amountToken = [Convert]::ToString("0x$($amountToken_end)",10)
    $miaStacked = [int]$amountToken

    #GET TOTAL USTX COMMITTED
    $amountUSTX_hex = ($amountToken_start.Substring($amountToken_start.LastIndexOf("01000000000000000000000"))).Substring(23)
    $amountUSTX = [Convert]::ToString("0x$($amountUSTX_hex)",10)
    $stxCommitted = [int64]$amountUSTX / 1000000

    $myShare = $myStack / $miaStacked
    $myReward = $myShare * $stxCommitted

    #Get Current Block
    $req_block = Invoke-RestMethod -Uri "https://stacks-node-api.mainnet.stacks.co/v2/info"
    $current_block = $req_block.stacks_tip_height

    #Cycle Progress
    $genesis = 24497
    $cycle_start = (2100 * $cycle_dec) + $genesis
    $progress = ($current_block - $cycle_start) / 2100
    $hours_remain = [math]::Round((($cycle_start + 2100 - $current_block) * 10) / 60,2)
    $days_remain = [math]::Round($hours_remain / 24,2)
    if($hours_remain -gt 24) {
        $time_remain = "$($days_remain) days"
    } else {
        $time_remain = "$($hours_remain) hours"
    }

    #OUTPUT
    $obj = New-Object PSObject -Property @{
        'Stacking Cycle' = $cycle_dec
        'MIA Stacked' = $miaStacked.ToString("#,###")
        'STX to Stackers' = $stxCommitted.ToString("#,###")
        'My MIA Stack' = $myStack.ToString("#,###")
        'My Reward Share' = $myShare.ToString("0.0%")
        'Current STX Reward' = ($myReward).ToString("#,###")
        'Current USD Reward' = ($myReward * $price_stxusd).ToString("$#,###")
        'Current BTC Reward' = [math]::Round($myReward * $price_stxbtc,8)
        'Percent Complete' = $progress.ToString("0.000%")
        'Potential STX Reward' = (($myReward) / $progress).ToString("#,###")
        'Potential USD Reward' = (($myReward * $price_stxusd) / $progress).ToString("$#,###")
        'Potential BTC Reward' = [math]::Round((($myReward * $price_stxbtc) / $progress),8)
        'STX-USD Price' = $price_stxusd.ToString("$#,###.00")
        'STX-BTC Price' = ($price_stxbtc * 100000000).ToString("#,### Satoshis")
        'Time Remaining' = $time_remain
    
    }
    $obj | Format-List 'Stacking Cycle', 'MIA Stacked', 'STX to Stackers', 'My MIA Stack', 'My Reward Share', 'Current STX Reward', 'Current USD Reward', 'Current BTC Reward', 'Percent Complete', 'Time Remaining', 'Potential STX Reward', 'Potential USD Reward', 'Potential BTC Reward', 'STX-USD Price', 'STX-BTC Price'
}

getMiaStackStats -sender_address "SPTBH1YJX2YK57A4BPMQ2V15HZDKRGMS81FC3ZTK" -cycle 4 -myStack 525000


