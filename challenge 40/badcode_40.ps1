#Fuck error messages, I don't like them! They make the console all red!
$ErrorActionPreference = 'SilentlyContinue'

$mode = 0


function Convert-CharToT9($char){

#This is how it's supposed to be translated...

<#
|-----------------------|
|   1   |   2   |   3   |
|  .,?! |  abc  |  def  |
|-----------------------|
|   4   |   5   |   6   |
|  ghi  |  jkl  |  mno  |
|-----------------------|
|   7   |   8   |   9   |
|  pqrs |  tuv  |  wxyz |
|-----------------------|
|   *   |   0   |   #   |
|  '-+= |   ⎵  |  case |
|-----------------------|
#>
    

    #Powershell can have one-liners, too!
    (Get-LookupTable (((((gcm $MyInvocation.MyCommand)) | select -exp "defi*").split([System.Environment]::NewLine) | %{ if($mode -eq 0){ if($_ -eq '<#'){ $mode = 1 }} else {if($_ -eq '#>'){$mode = 0} else {$_}}} | ? {$_ -notlike ''}) -join ([System.Environment]::NewLine)))[$char]
}

function Get-LookupTable($text){
    $lookup = @{}

    $count = 0

    $nums = @(0,0,0)


    $text.Split([Environment]::NewLine) | %{ 
        $count = ($count + 1)%6
        $magicNums = @(32)
        $magicNums2 = @(124,32)
        $magicNum = 3
        $magicNum2 = 5
        $specialMagicNum = 124
        $verySpecialMagicNumber = 9141
        $esspeciallyMagicNumberToMakeVerySpecialMagicNumberNormal = 9109


        if($count -eq $magicNum) {
            $nums = @(0,0,0)
            $count2 = 0
            $_.toCharArray() | %{
                if($magicNums2 -notcontains $_){
                    $nums[$count2] = $_
                    $count2 = $count2 + 1
                }
            }
        } elseif ($count -eq $magicNum2) {
            $count3 = 0
            $count4 = 0
            $_.toCharArray() | %{
                if($magicNums -notcontains $_){
                    $count4 = $count4 + 1
                    if($_ -eq $specialMagicNum){
                        if($count3 -ne 0){
                            $value = ([string]$nums[$count3-1])*($count4)
                            if([int]$nums[$count3-1] -ne 35){
                                $lookup[$nums[$count3-1]] = $value
                            }
                        }
                        $count3 = $count3 + 1
                        $count4 = 0
                    } elseif ($true) {
                        $count4 = $count4
                        $value = ([string]$nums[$count3-1])*$count4
                        if([int]$nums[$count3-1] -ne 35){
                            if([int]$_ -ne $verySpecialMagicNumber){
                                $lookup[$_] = $value
                            } else {
                                $lookup[[char](([int]$_)-$esspeciallyMagicNumberToMakeVerySpecialMagicNumberNormal)] = $value
                            }
                        }
                    }
                }
            }
        }
    }
    $lookup
}

function Get-CapsTable($text){
    
    $table = @{}
    $capsmode = "l"
    
    for($i = 0; $i+1 -le $text.Count; $i = $i + 1){
        $currentCharAsString = $text[$i]
        if($currentCharAsString.ToString() -eq " "){
           
        }else{
           if($i+1 -eq $text.Count){
                if(($capsmode -eq 'l') -and (($currentCharAsString.ToString() -ceq $currentCharAsString.ToString().toUpper())) -and ([int][char]$currentCharAsString.ToString().ToLower() -ge 97) -and ([int][char]$currentCharAsString.ToString().ToLower() -lt 122)){
                    $table[$i] = "#"
                }
            }elseif(($capsmode -eq 'l') -and (($currentCharAsString.ToString() -ceq $currentCharAsString.ToString().toUpper()))){
                    $nextChar = $text[$i+1]
                    if($nextChar.ToString() -ceq $nextChar.ToString().ToUpper() -and ([int][char]$nextChar.ToString().ToLower() -ge 97) -and ([int][char]$nextChar.ToString().ToLower() -lt 122)){
                        $capsmode = "u"
                        $table[$i] = "## "
                    } elseif (([int][char]$currentCharAsString.ToString().ToLower() -ge 97) -and ([int][char]$currentCharAsString.ToString().ToLower() -lt 122)) {
                        $table[$i] = "# "
                    }
            }elseif(($capsmode -eq 'u') -and (-not ($currentCharAsString.ToString() -ceq $currentCharAsString.ToString().toUpper()))){
                $capsmode = 'l'
                $table[$i] = "# "
            }
            
        }
    }
    $table
}

function to_t9($text){
    $charArray = $text.toCharArray()
    
    $caps = Get-CapsTable($charArray)

    $charArray = $text.toLower().ToCharArray()

    $counter = 0

    $result = ($charArray | %{
        "$($caps[$counter])" + (Convert-CharToT9 ($_))
        $counter = $counter +1
    }) -join ' '

    1..9 | %{
        $result = $result -replace "$_ $_","$($_)_$($_)"
    }
    $result
}

'Hello World'
to_t9('Hello World') 
"# 44 33 555_555 666 0 # 9 666 777 555 3"

'HELLO WORLD'
to_t9('HELLO WORLD') 
"## 44 33 555_555 666 0 9 666 777 555 3"

'abba feed high'
to_t9('abba feed high') 
"2_22_22_2 0 333_33_33_3 0 44_444_4_44"

'I love PHP'
to_t9('I love PHP') 
"# 444 0 555 666 888 33 0 ## 7 44 7"

'there r 4 lights!'
to_t9('there r 4 lights!') 
"8 44 33 777 33 0 777 0 4444 0 555 444_4_44 8 7777 1111"