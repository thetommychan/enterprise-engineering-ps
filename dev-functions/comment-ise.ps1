# Toggle Comment function for commenting out multiple lines
$psise.CurrentPowerShellTab.AddOnsMenu.Submenus.Add('Toggle Comment', { Toggle-Comment }, 'CTRL+K')
function Toggle-Comment
{
    $file = $psise.CurrentFile                              
    $text = $file.Editor.SelectedText   
    if ($text.StartsWith("<#")) {
        $comment = $text.Substring(2).TrimEnd("#>") 
    }
    else
    {                            
        $comment = "<#" + $text + "#>"    
    }
    $file.Editor.InsertText($comment)                     
}