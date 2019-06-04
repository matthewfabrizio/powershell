# Add-CatUser

Named after my cats, and also because Add-ADUser would be kinda strange.

## Description

This script was written with the intention of automating the Active Directory creation of users. It uses a few AD specific cmdlets [shown below](#ad-cmdlets).

The script has no parameters because of the use of `Out-GridView` at the start of the script. Upon execution, `Out-GridView` displays a (ugly) GUI dialog of all user sheets in the `user_sheets` directory. Upon choosing a sheet, it is saved in a variable for later use.

*Note: The script may not work 100% as I had to change information to fit a proper demo, but with some playing around it isn't hard to get working.*

## AD cmdlets

|
|-|
|`Get-ADUser`|
|`New-ADUser`|
|`Add-ADGroupMember`|
|`Get-ADOrganizationalUnit`|
|`New-ADOrganizationalUnit`|
|`Get-ADDomain`|

## User Sheets

User sheets are stored in the `user_sheets` directory and can be any name you'd like.

The sheets need to follow a specific standard, shown as follows:

||||||
|-|-|-|-|-|
|Building|First|Last|GradYear|Course|

There are a few things to keep in mind while creating user sheets.
- The building column should match whatever you have in `info-json`.
- First and last name need to be separate
- GradYear should be a four digit integer (obviously)
- Course NEEDS to be __*specific*__ to your AD setup.

Example for a course called CAD. The course description standard might be `CAD Class - Building1` and the group they are in may be called `CAD Group Building1`. Obviously, you can see where this gets a little tricky. This is where the `info.json` file comes into play.

## Password Generation

Passwords are randomly generated for each user based on their first and last name. You can see this implementation on `line 126`.

Change this if you have a different policy for handing out passwords, each place does it different.

## `info.json`

`info.json` contains four (4) unique identifiers, being `Static`, `Buildings`, `Groups`, and `Descriptions`.

`Static`
- Contains information that NEVER changes

`Buildings`
- Contains multiple buildings and SPECIFIC information to those buildings (remove Building2 if only working with one location)

`Groups`
- Contains a **group mapping** to the course name. This is VERY important for the script to work properly and for your own sanity.

`Descriptions`
- Contains a **descriptions mapping** to the course name. This is VERY important for the script to work properly and for your own sanity.

## `Groups` and `Descriptions` mapping (example)

To briefly recap on the summary above, look at the `info.json` file, specifically lines `26-35`. You will notice each mapping starts with `Course1-3` as the identifier, with different values (these correspond to each Course a user is assigned to in the user sheet). 

Let's look at an example CSV and example mappings.

||||||
|-|-|-|-|-|
|Building|First|Last|GradYear|Course|
|Building1|Bob|Brown|2022|Sailing

`info.json snippet`
```json
"Groups" : {
    "Sailing" : "Sailors Group"
},
"Descriptions" : {
    "Sailing" : "Sailing - Building1"
}
```

As you can see, when you have different groups and descriptions, things can get a little sneaky. This was the best method of dealing with this roadblock. Obviously, if you have everyting matching, you can just remove this portion of the JSON.

## What I've Gained
- Logging
- Validating/sanitizing input
- Out-GridView
- JSON
- Keeping personal details separate from hard coding in the script (WITH JSON!)