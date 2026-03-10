$walletsFile = "C:\Users\Admin\Desktop\PAYI\backend\Payi.Api\Data\wallets.json"
$transactionsFile = "C:\Users\Admin\Desktop\PAYI\backend\Payi.Api\Data\transactions.json"

$myEmail = "mutindimusa04@gmail.com"
$merchantEmail = "merchant@payi.dev"

$wallets = Get-Content $walletsFile | ConvertFrom-Json
$myWallet = $wallets | Where-Object { $_.userEmail -eq $myEmail }

if ($null -eq $myWallet.balances) {
    $myWallet | Add-Member -MemberType NoteProperty -Name balances -Value @{} -Force
}

$myWallet.balances | Add-Member -MemberType NoteProperty -Name KES -Value 4997 -Force
$myWallet.balances | Add-Member -MemberType NoteProperty -Name USD -Value 4997 -Force
$myWallet.balances | Add-Member -MemberType NoteProperty -Name NGN -Value 14940 -Force
$myWallet.updatedAtUtc = (Get-Date).ToUniversalTime().ToString("O")

$wallets | ConvertTo-Json -Depth 10 | Set-Content $walletsFile

$transactions = Get-Content $transactionsFile | ConvertFrom-Json

function Add-Tx($user, $cp, $amt, $cur) {
    $randomStr = -join ((48..57) | Get-Random -Count 8 | % {[char]$_})
    $tx = @{
        reference = "SND-20260310-$randomStr"
        userEmail = $user
        direction = "Send"
        counterpartyName = $cp
        country = "Global"
        method = "Payi Transfer"
        amount = $amt
        currency = $cur
        status = "Completed"
        createdAtUtc = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffffffZ")
    }
    return $tx
}

$transactions += Add-Tx $myEmail "merchant@payi.dev" 1 "KES"
$transactions += Add-Tx $myEmail "merchant@payi.dev" 2 "KES"

$transactions += Add-Tx $myEmail "merchant@payi.dev" 1 "USD"
$transactions += Add-Tx $myEmail "merchant@payi.dev" 2 "USD"

$transactions += Add-Tx $myEmail "merchant@payi.dev" 10 "NGN"
$transactions += Add-Tx $myEmail "merchant@payi.dev" 20 "NGN"
$transactions += Add-Tx $myEmail "merchant@payi.dev" 30 "NGN"

$transactions | ConvertTo-Json -Depth 10 | Set-Content $transactionsFile

Write-Host "Successfully injected 7 transactions."
