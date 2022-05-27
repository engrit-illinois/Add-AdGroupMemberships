function Add-AdGroupMemberships {
	param(
		[Parameter(Mandatory=$true)]
		[string]$InputCsv,
		
		[string]$InputUserColumn = "User",
		[string]$InputGroupColumn = "Group",
		
		[string]$OutputCsv,
		
		[switch]$TestRun,
		
		[switch]$PassThru
	)

	function log {
		param(
			[string]$msg,
			[int]$L
		)
		for($i = 0; $i -lt $L; $i += 1) { $msg = "    $msg" }
		$ts = Get-Date -Format "yyyy-MM-dd_HH:mm:ss"
		$msg = "[$ts] $msg"
		Write-Host $msg
	}
	
	function addm($property, $value, $object, $adObject = $false) {
		if($adObject) {
			# This gets me EVERY FLIPPIN TIME:
			# https://stackoverflow.com/questions/32919541/why-does-add-member-think-every-possible-property-already-exists-on-a-microsoft
			$object | Add-Member -NotePropertyName $property -NotePropertyValue $value -Force
		}
		else {
			$object | Add-Member -NotePropertyName $property -NotePropertyValue $value
		}
		$object
	}
	
	function Get-CsvData {
		log "Importing membership data from CSV: `"$InputCsv`"..."
		$adds = Import-Csv $InputCsv
		$addsCount = "invalid"
		if($adds) { $addsCount = @($adds).count }
		log "Imported `"$addsCount`" rows." -L 1
		$adds
	}
	
	function Validate-User($membership) {
		log "Validating user..." -L 3
		$valid = $false
		
		$user = $membership.$InputUserColumn
		if($user) {
			log "User found in CSV data." -L 4
			if($user -ne "") {
				log "User in CSV data seems valid." -L 4
				$valid = $true
			}
			else {
				log "User in CSV data is an empty string!" -L 4
			}
		}
		else {
			log "User not found in CSV data!" -L 4
		}
		
		$membership = addm "UserValid" $valid $membership
		$membership
	}
	
	function Validate-Group($membership) {
		log "Validating group..." -L 3
		$valid = $false
		
		$group = $membership.$InputGroupColumn
		if($group) {
			log "Group found in CSV data." -L 4
			if($group -ne "") {
				log "Group in CSV data seems valid." -L 4
				$valid = $true
			}
			else {
				log "Group in CSV data is an empty string!" -L 4
			}
		}
		else {
			log "Group not found in CSV data!" -L 4
		}
		
		$membership = addm "GroupValid" $valid $membership
		$membership
	}
	
	function Validate-CsvInput($membership) {
		log "Validating user and group data from CSV input..." -L 2
			
		$membership = Validate-User $membership
		$membership = Validate-Group $membership
		
		if(
			(-not $membership.UserValid) -and
			(-not $membership.GroupValid)
		) {
			$err = "User and group data are both invalid!"
			log $err -L 2
		}
		elseif(-not $membership.UserValid) {
			$err = "User data is invalid!"
			log $err -L 2
		}
		elseif(-not $membership.GroupValid) {
			$err = "Group data is invalid!"
			log $err -L 2
		}
		else {
			log "User and group data both seem valid." -L 2
		}
		
		if($err) {
			$membership.Error = $true
			$membership.Result = $err
		}
		
		$membership
	}

	function Test-UserExists($membership) {
		log "Testing whether user object exists in AD..." -L 3
		$exists = $false
		
		try {
			$response = Get-ADUser -Identity $membership.$InputUserColumn
		}
		catch {
			$err = $_.Exception.Message
			log $err -L 3
		}
		
		if(-not $err) {
			if(-not $response) {
				$err = "User not found in AD!"
				log $err -L 3
			}
			else {
				if(-not $response.Name) {
					$err = "Response to AD user query not recognized!"
					log $err -L 3
				}
				else {
					if(-not ($response.Name -eq $membership.$InputUserColumn)) {
						$err = "Response to AD user query returned unexpected results!"
						log $err -L 3
					}
					else {
						log "User found in AD." -L 3
						$exists = $true
					}
				}
			}
		}
		
		if($err) {
			$membership.Error = $true
			$membership.Result = $err
		}
		
		$membership = addm "UserExists" $exists $membership
		$membership
	}
	
	function Test-GroupExists($membership) {
		log "Testing whether group object exists in AD..." -L 3
		$exists = $false
		
		try {
			$response = Get-ADGroup -Identity $membership.$InputGroupColumn
		}
		catch {
			$err = $_.Exception.Message
			log $err -L 3
		}
		
		if(-not $err) {
			if(-not $response) {
				$err = "Group not found in AD!"
				log $err -L 3
			}
			else {
				if(-not $response.Name) {
					$err = "Response to AD group query not recognized!"
					log $err -L 3
				}
				else {
					if(-not ($response.Name -eq $membership.$InputGroupColumn)) {
						$err = "Response to AD group query returned unexpected results!"
						log $err -L 3
					}
					else {
						log "Group found in AD." -L 3
						$exists = $true
					}
				}
			}
		}
		
		if($err) {
			$membership.Error = $true
			$membership.Result = $err
		}
		
		$membership = addm "GroupExists" $exists $membership
		$membership
	}
	
	function Test-ObjectsExist($membership) {
		log "Testing whether user and group objects exist in AD..." -L 2
			
		$membership = Test-UserExists $membership
		$membership = Test-GroupExists $membership
		
		if(
			(-not $membership.UserExists) -and
			(-not $membership.GroupExists)
		) {
			$err = "Neither user nor group objects exist in AD!"
			log $err -L 2
		}
		elseif(-not $membership.UserExists) {
			$err = "User object doesn't exist in AD!"
			log $err -L 2
		}
		elseif(-not $membership.GroupExists) {
			$err = "Group object doesn't exist in AD!"
			log $err -L 2
		}
		else {
			log "User and group objects both exist in AD." -L 2
		}
		
		if($err) {
			$membership.Error = $true
			$membership.Result = $err
		}
		
		$membership
	}
	
	function Test-MembershipExists($membership) {
		log "Checking if membership already exists..." -L 2
		$exists = $false
		
		try {
			$existingMembers = Get-ADGroupMember -Identity $membership.$InputGroupColumn | Select -ExpandProperty Name
		}
		catch {
			$err = $_.Exception.Message
			log $err -L 3
		}
		
		if(-not $err) {
			if(@($existingMembers) -contains $membership.$InputUserColumn) {
				$err = "Group already contains user."
				log $err -L 3
			}
			else {
				log "Membership doesn't already exist." -L 3
			}
		}
		
		if($err) {
			$membership.Error = $true
			$membership.Result = $err
		}
		
		$membership
	}
	
	function Add-Membership($membership) {
		log "Adding membership..." -L 2
		
		if($TestRun) {
			$result = "-TestRun was specified. Skipping the actual membership additions."
			log $result -L 3
			$membership.Result = $result
		}
		else {
			try {
				$response = Add-ADGroupMember -Identity $membership.$InputGroupColumn -Members $membership.$InputUserColumn -PassThru
			}
			catch {
				$err = $_.Exception.Message
				log $err -L 3
			}
			
			if(-not $err) {
				if(-not $response) {
					$err = "No data returned! Operation assumed failed."
					log $err -L 3
				}
				else {
					if(-not $response.Name) {
						$err = "Unexpected data returned! Result uncertain."
						log $err -L 3
					}
					else {
						$result = "Successfully added membership."
						log $result -L 3
						$membership.Result = $result
					}
				}
			}
			
			if($err) {
				$membership.Error = $true
				$membership.Result = $err
			}
		}
		
		$membership
	}
	
	
	function Process-Data($memberships) {
		log "Processing imported memberships..."
		
		$memberships = $memberships | ForEach-Object {
			$membership = $_
			$user = $membership.$InputUserColumn
			$group = $membership.$InputGroupColumn
			log "Processing membership: user `"$user`", group `"$group`"..." -L 1
			
			$membership = addm "Result" "Unknown" $membership
			$membership = addm "Error" $false $membership
			
			$membership = Validate-CsvInput $membership
			
			if(-not $membership.Error) {
				$membership = Test-ObjectsExist $membership
				
				if(-not $membership.Error) {
					$membership = Test-MembershipExists $membership
					
					if(-not $membership.Error) {
						$membership = Add-Membership $membership
					}
				}
			}
			
			$membership
		}
		
		$memberships
	}
	
	function Print-Memberships($memberships) {
		$memberships | Format-Table -AutoSize
	}
	
	function Output-Csv($memberships) {
		if($OutputCsv) {
			$memberships | Export-Csv -NoTypeInformation -Encoding "Ascii" -Path $OutputCsv
		}
	}
	
	function Do-Stuff {
		$memberships = Get-CsvData
		$memberships = Process-Data $memberships
		Print-Memberships $memberships
		Output-Csv $memberships
		if($PassThru) { $memberships }
	}
	
	Do-Stuff
	
	log "EOF"
}