#Fuck error messages, I don't like them! They make the console all red!
$ErrorActionPreference = 'SilentlyContinue'

#Just a global variable used within Convert-CharToT9 to extract the comment from the function definition
#1 = this line is part of the comment - process, 0 if its not part of the comment.
#I used a global var, just because
$mode = 0


# This function translates a single char to key presses (e.g. o becomes 666)
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
    # 
    #"gcm $MyInvocation.MyCommand" gives the current command/function as an object, the select expands the property "Definition" (you can use wildcards there! yay!), so that we get the function body as text.
    #The function definition is now split into lines and fed into a Foreach-Loop (%)
    #The Loop does nothing, until it reaches "<#" the start of the comment outlining the above graphic of the phone pad
    #This comment (and only the comment) is passed to further processing. All empty lines are removed and the single lines are joined into a multiline string.
    #This string not get's passed as an argument to "Get-LookupTable", which returns a Hashtable that tells us, which character corresponds to which key sequence
    #From there, the hashtable entry for the single char that was passed to this function is returned and the whole hashtable we just parsed from the comment above is discarded
    #
    #Yes, that whole monstrosity gets executed FOR EVERY CHARACTER that needs to be translated and so said ascii table above gets parsed for every character!
}

# This function parses the ascii art table above into usable data for character translation!
function Get-LookupTable($text){
    # This is the data structure, that determines how characters are to be translated
    $lookup = @{}

    # To simplify parsing, only some lines need to be read. This is a counter
    $count = 0

    # these are the numbers read from the current row of the table. Powershell has arrays of fixed size
    #And it's easiest to just create an array with valid(haha, good luck finding bugs) data, that should get overwritten
    $nums = @(0,0,0)


    $text.Split([Environment]::NewLine) | %{ 
        # Count the lines, it's 6 lines per table row, so increment counter and mod 6
        $count = ($count + 1)%6
        # to identify spaces (this will be skipped while parsing) - ASCII
        #Used to isolate the characters in the cells of the table
        $magicNums = @(32)
        # to identify spaces and pipes (this will be skipped while parsing) - ASCII
        #Used to isolate the characters in the cells of the table - should only be 3 characters in each row after stripping those
        $magicNums2 = @(124,32)
        # denotes the line in which we can find the numbers to parse out
        $magicNum = 3
        # denotes the line in which we can find the characters to parse out
        $magicNum2 = 5
        # when parsing characters, we need to track when we switch to the next cell (and thus number)
        #This is a pipe in ASCII
        $specialMagicNum = 124
        # Remember the space symbol in the table? This is it's code!
        $verySpecialMagicNumber = 9141
        # 9141 from above minus this number results in 32 - the ASCII code of a space :-)
        $esspeciallyMagicNumberToMakeVerySpecialMagicNumberNormal = 9109


        if($count -eq $magicNum) {
            # We're in the line, that contains the numbers
            #Reset array
            $nums = @(0,0,0)
            # Why use for and get a counter for free, when you have foreach?
            $count2 = 0
            $_.toCharArray() | %{
                # strip all spaces and pipes from current line, leave only the three numbers. Put these into an array
                if($magicNums2 -notcontains $_){
                    $nums[$count2] = $_
                    $count2 = $count2 + 1
                }
            }
        } elseif ($count -eq $magicNum2) {
            # We're in a line, that contains characters
            $count3 = 0
            $count4 = 0
            $_.toCharArray() | %{
                # Only process characters, that are not a space
                if($magicNums -notcontains $_){
                    $count4 = $count4 + 1
                    # oh, we hit a pipe - save last character and next cell entered!
                    if($_ -eq $specialMagicNum){
                        # First char is a pipe, so discard that, else write the character lookup
                        if($count3 -ne 0){
                            # did you know, that you can multiply strings with ints to get the string repeated?
                            # 'a'*5 results in 'aaaaa' - nice feature here!
                            $value = ([string]$nums[$count3-1])*($count4)
                            # Special case - we're in the last field and don't want to map c,a,s or e to #
                            # as this means to shift case So... skip it. Else put this into the data structure
                            if([int]$nums[$count3-1] -ne 35){
                                $lookup[$nums[$count3-1]] = $value
                            }
                        }
                        $count3 = $count3 + 1
                        $count4 = 0
                    # Why use else, when elseif work's too?
                    } elseif ($true) {
                        # WTF? uhmmm.... this was not intentional, I swear! or was it?
                        $count4 = $count4
                        # Same as above, repeat string by multiplication!
                        $value = ([string]$nums[$count3-1])*$count4
                        # And... yeah - skip the case button!
                        if([int]$nums[$count3-1] -ne 35){
                            # Check for the ⎵
                            if([int]$_ -ne $verySpecialMagicNumber){
                                $lookup[$_] = $value
                            } else {
                                # result is 32, which is ASCII -> space
                                $lookup[[char](([int]$_)-$esspeciallyMagicNumberToMakeVerySpecialMagicNumberNormal)] = $value
                            }
                        }
                    }
                }
            }
        }
    }
    # This feels like bad code, but in Powershell, every value that doesn't get put into a pipeline or variable is automagically returned
    # this would even work, when there's code below this line. This doesn't return from the function but returns this value and continues execution
    $lookup
}

# This function is used to determine, when to press the caps button and also how often (caps vs. caps-lock)
# it returns a hastable, index is the character position (original text) on which the caps button is to be inserted in the string
# heuristic for caps-lock: if there are at least two charactes in a row that are in caps, got to caps lock
function Get-CapsTable($text){
    
    # The hastable that will hold the position (and also which caps mode # or ##)
    $table = @{}
    # l means 'l'owercase, u means 'u'ppercase ahem... caps lock, a single uppercase letter won't change this
    $capsmode = "l"
    
    for($i = 0; $i+1 -le $text.Count; $i = $i + 1){
        # Powershell is dynamically typed. So better make sure, we make sure, that
        # variable names tell us about the type.
        # It would be a shame, if someone would put anything else in this variable than a string.
        # ooops... isn't $text an array of chars? Who'd be so crazy to do this?
        $currentCharAsString = $text[$i]
        
        # space is the same in uppercase and I don't want a case in front of every space - so skip it!
        # Also - an if without else feels really lonely, right?
        if($currentCharAsString.ToString() -eq " "){
           
        }else{
           # We're at the last character. a) No caps lock needed, b) don't create an index out of bounds!
           if($i+1 -eq $text.Count){
                # If not in caps lock and this character is uppercase, save a single caps on this position
                if(($capsmode -eq 'l') -and (($currentCharAsString.ToString() -ceq $currentCharAsString.ToString().toUpper())) -and ([int][char]$currentCharAsString.ToString().ToLower() -ge 97) -and ([int][char]$currentCharAsString.ToString().ToLower() -lt 122)){
                    $table[$i] = "#"
                }
            # Not the last character, we're lowercase and next character is uppercase
            }elseif(($capsmode -eq 'l') -and (($currentCharAsString.ToString() -ceq $currentCharAsString.ToString().toUpper()))){
                    $nextChar = $text[$i+1]
                    # If the second next character is also uppercase, switch to caps lock! - only if that one is a-z
                    if($nextChar.ToString() -ceq $nextChar.ToString().ToUpper() -and ([int][char]$nextChar.ToString().ToLower() -ge 97) -and ([int][char]$nextChar.ToString().ToLower() -lt 122)){
                        $capsmode = "u"
                        $table[$i] = "## "
                    # Else a single caps, if it's a-z and not a symbol or number
                    } elseif (([int][char]$currentCharAsString.ToString().ToLower() -ge 97) -and ([int][char]$currentCharAsString.ToString().ToLower() -lt 122)) {
                        $table[$i] = "# "
                    }
            # Not the last character, we're in upper case but next character is lower case. Switch it off at this position!
            }elseif(($capsmode -eq 'u') -and (-not ($currentCharAsString.ToString() -ceq $currentCharAsString.ToString().toUpper()))){
                $capsmode = 'l'
                $table[$i] = "# "
            }
            
        }
    }
    # Now return all positions on which a caps key is to be inserted.
    $table
}

# This function takes a string and uses all of the above to convert it.
function to_t9($text){

    # First, we want a char array for the following
    $charArray = $text.toCharArray()
    
    # Build the data structure on where to insert the caps (lock) key
    $caps = Get-CapsTable($charArray)

    # Wait? Overwritten? Yeah, we need everything lowercase!
    $charArray = $text.toLower().ToCharArray()

    # as above - why use for, when you can use foreach and count manually
    $counter = 0

    # For every character: insert the caps (lock) directly followed by the character code
    # If you access an hashtable with an unknown index, powershell returns an empty string.
    # so we don't need to check for valid positions and just read it...
    $result = ($charArray | %{
        # Remember? all "dangling" values get inserted into the pipeline as if they were returned
        #but this won't stop the execution!
        "$($caps[$counter])" + (Convert-CharToT9 ($_))
        $counter = $counter +1
    # All values for the Foreach are returned as an array, join everything with a space
    }) -join ' '

    # Oh.. if two consecutive characters use the same key, denote it with an undescore instead of a space
    # F%@k it, I don't wan't to make this clean. For all numbers from 0 to 9 plus the * and # key, replace every occurence of a space
    # that hast this character in front of it AND after it with an underscore. Also do it twice for those pesky single digit key presses that are missed otherwise
    0..9 + @('*','#') | %{
        $result = ($result -replace "$_ $_","$($_)_$($_)") -replace "$_ $_","$($_)_$($_)"
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