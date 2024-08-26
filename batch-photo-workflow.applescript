on run
	-- Prompt the user to choose files in a folder
	set folderPath to choose folder with prompt "Select the folder containing the items to process:"
	
	set sizeList to {"1080", "2160"}
	set defaultSizeOption to "2160"
	set sizePromptMessage to "Please select a timing direction:"
	set selectedSizeOption to choose from list sizeList with prompt sizePromptMessage default items defaultSizeOption with title "Select Option" OK button name "Confirm" cancel button name "Cancel"
	if selectedSizeOption is false then
		-- User clicked Cancel
		error number -128
	else
		-- User made a selection
		set selectedSizeOption to item 1 of selectedSizeOption
		log "User selected: " & selectedSizeOption
		-- You can now use the selectedOption variable in your script
		set OPTION_minSize to selectedSizeOption
	end if
	
	set sharpenList to {"1", "2"}
	set defaultSharpenOption to "2"
	set sharpenPromptMessage to "Please select a timing direction:"
	set selectedSharpenOption to choose from list sharpenList with prompt sharpenPromptMessage default items defaultSharpenOption with title "Select Option" OK button name "Confirm" cancel button name "Cancel"
	if selectedSharpenOption is false then
		-- User clicked Cancel
		error number -128
	else
		-- User made a selection
		set selectedSharpenOption to item 1 of selectedSharpenOption
		log "User selected: " & selectedSharpenOption
		-- You can now use the selectedOption variable in your script
		set OPTION_sharpenNumber to selectedSharpenOption
	end if
	
	set outputFolderName to "output" -- Change this to your desired output folder name
	set outputPath to (folderPath as text) & outputFolderName & ":" -- Construct the output path
	set outputPOSIXPath to POSIX path of outputPath
	set magickBin to "/opt/homebrew/Cellar/imagemagick/7.1.1-36/bin/magick"
	
	# other options
	#set OPTION_gaussianBlurNumber to 3
	#set OPTION_cropNumber to "120x120+10+5"
	
	tell application "System Events"
		-- Check if the output folder exists
		if (exists folder outputPath) then
			-- If it exists, remove it
			do shell script "rm -rf " & quoted form of outputPOSIXPath
		end if
		-- Create the output folder again
		do shell script "mkdir -p " & quoted form of outputPOSIXPath
	end tell
	# sips task
	resizeTasksBySips(folderPath, OPTION_minSize, outputPOSIXPath)
	# imagemagick tasks
	set imagemagickTasksFolder to convertPathTo(outputPOSIXPath, "alias")
	imagemagickTasks(imagemagickTasksFolder, outputPOSIXPath, {OPTION_sharpenNumber})
end run

on imagemagickTasks(folderPath, outputPath, params)
	set {sharpenNumber} to params
	tell application "Finder"
		set itemList to every file of folderPath
		set totalItems to count of itemList
	end tell
	repeat with i from 1 to totalItems
		set currentItem to item i of itemList
		set isLastItem to (i = totalItems)
		set itemPath to (POSIX path of (currentItem as alias))
		set newItemPath to sharpenItem(itemPath, outputPath, sharpenNumber)
		#set newItemPath to cropItem(newItemPath, outputPath, cropNumber)
		#set newItemPath to gaussianBlurItem(newItemPath, outputPath, gaussianBlurNumber)
	end repeat
end imagemagickTasks

on sharpenItem(itemPath, outputPath, param)
	set {filename, fileBaseName, fileExtension, outputDirectory} to getItemFileInfo(itemPath, outputPath)
	set toItemPath to outputDirectory & fileBaseName & "-sharpen-" & param & "." & fileExtension
	set shellCommand to my magickBin & " " & quoted form of itemPath & " " & " -sharpen " & param & " " & quoted form of toItemPath
	log shellCommand
	do shell script shellCommand
	do shell script "rm " & quoted form of itemPath
	return toItemPath
end sharpenItem

on cropItem(itemPath, outputPath, param)
	set {filename, fileBaseName, fileExtension, outputDirectory} to getItemFileInfo(itemPath, outputPath)
	set toItemPath to outputDirectory & fileBaseName & "-crop-" & param & "." & fileExtension
	set shellCommand to my magickBin & " " & quoted form of itemPath & " " & " -crop " & param & " " & quoted form of toItemPath
	log shellCommand
	do shell script shellCommand
	do shell script "rm " & quoted form of itemPath
	return toItemPath
end cropItem

on gaussianBlurItem(itemPath, outputPath, param)
	set {filename, fileBaseName, fileExtension, outputDirectory} to getItemFileInfo(itemPath, outputPath)
	set toItemPath to outputDirectory & fileBaseName & "-gaussian-blur-" & param & "." & fileExtension
	set shellCommand to my magickBin & " " & quoted form of itemPath & " " & " -gaussian-blur 0x" & param & " " & quoted form of toItemPath
	log shellCommand
	do shell script shellCommand
	do shell script "rm " & quoted form of itemPath
	return toItemPath
end gaussianBlurItem

on resizeTasksBySips(folderPath, minSize, outputPath)
	log folderPath
	tell application "Finder"
		set itemList to every file of folderPath
		set totalItems to count of itemList
	end tell
	repeat with i from 1 to totalItems
		set currentItem to item i of itemList
		set isLastItem to (i = totalItems)
		set itemPath to (POSIX path of (currentItem as alias))
		resizeItemBySips(itemPath, minSize, outputPath)
	end repeat
end resizeTasksBySips

on resizeItemBySips(itemPath, minSize, outputPath)
	set {filename, fileBaseName, fileExtension, outputDirectory} to getItemFileInfo(itemPath, outputPath)
	set toResizeItemPath to outputDirectory & fileBaseName & "-size-" & minSize & "." & fileExtension
	set shellCommand to "sips -Z " & getCalcSize(itemPath, minSize) & " " & quoted form of itemPath & " --out " & quoted form of toResizeItemPath
	log shellCommand
	do shell script shellCommand
end resizeItemBySips

on getItemFileInfo(itemPath, outputPath)
	set {filename, fileExtension} to getFileNameAndExtension(itemPath)
	set fileBaseName to replaceString(filename, "." & fileExtension, "")
	set outputDirectory to replaceString(outputPath, filename, "")
	return {filename, fileBaseName, fileExtension, outputDirectory}
end getItemFileInfo

on getFileNameAndExtension(imageFilePath)
	-- Convert the POSIX path to an AppleScript file reference
	set fileRef to (POSIX file imageFilePath) as alias
	-- Get the name and name extension
	set filename to name of (info for fileRef)
	set fileExtension to name extension of (info for fileRef)
	return {filename, fileExtension}
end getFileNameAndExtension

on replaceString(originalString, searchString, replacementString)
	-- Set the text item delimiters to the search string
	set AppleScript's text item delimiters to searchString
	-- Split the original string into text items
	set stringParts to text items of originalString
	-- Restore the text item delimiters
	set AppleScript's text item delimiters to replacementString
	-- Combine the parts back together with the replacement string
	set newString to stringParts as string
	-- Restore the text item delimiters to default
	set AppleScript's text item delimiters to {""}
	return newString
end replaceString

on convertPathTo(inputPath, requestedForm)
	try
		-- Convert input path to standard POSIX path
		set standardPosixPath to POSIX path of inputPath
		-- Handle the requested path format
		if requestedForm is "posix" then
			set transformedPath to standardPosixPath
			-- Remove trailing slash if present
			if transformedPath ends with "/" then
				set transformedPath to text 1 thru -2 of transformedPath
			end if
		else if requestedForm is "alias" then
			set transformedPath to POSIX file standardPosixPath as alias
		else if requestedForm is "hfs" then
			set transformedPath to POSIX file standardPosixPath as string
		else
			error "Unexpected type: " & requestedForm
		end if
		return transformedPath
	on error e
		log "Error in convertPathTo: " & e
		return false
	end try
end convertPathTo

on getCalcSize(itemPath, minSize)
	-- Get the dimensions of the image using sips
	set dimensions to do shell script "sips -g pixelWidth -g pixelHeight " & quoted form of itemPath
	-- Parse the dimensions
	set pixelWidth to (paragraph 2 of dimensions) as string
	set pixelHeight to (paragraph 3 of dimensions) as string
	-- Extract the numeric values
	set pixelWidth to word 2 of pixelWidth
	set pixelHeight to word 2 of pixelHeight
	set aspectRatio to pixelWidth / pixelHeight
	if pixelWidth > pixelHeight then
		set calcSize to aspectRatio * minSize
	else
		set calcSize to minSize / aspectRatio
	end if
	return calcSize
end getCalcSize

