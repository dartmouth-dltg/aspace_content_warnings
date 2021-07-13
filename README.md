ArchivesSpace Offensive Content Tags
=============================

## Getting started

This plugin has been tested with ArchivesSpace versions 2.8.0+.

Unzip the latest release of the plugin to your
ArchivesSpace plugins directory:

     $ cd /path/to/archivesspace/plugins
     $ unzip aspace_offensive_content_tags.zip -d aspace_offensive_content_tags

Enable the plugin by editing your ArchivesSpace configuration file
(`config/config.rb`):

     AppConfig[:plugins] = ['other_plugin', 'aspace_offensive_content_tags]

(Make sure you uncomment this line (i.e., remove the leading '#' if present))

See also:

  https://github.com/archivesspace/archivesspace/blob/master/plugins/README.md

You will need to shut down ArchivesSpace and migrate the database:

     $ cd /path/to/archivesspace
     $ scripts/setup-database.sh

See also:

  https://github.com/archivesspace/archivesspace/blob/master/UPGRADING.md
  
This will create the tables required by the plugin, and will pre-populate the 
system with a set of Offensive Content Tags. The controlled value list is editable. 

## Configuration

This plugin accepts two configuration options. One controls the visibility of Offensive Content Tags
as facets in the staff application and the other controls the visibility of Offensive Content Tags
as facets in the PUI. Set either `staff_faceting` or `public_faceting` to `true` to
enable Offensive Content Tags facets in that area.

```
AppConfig[:aspace_offensive_content_tags] = {
  'staff_faceting' => true,
  'public_faceting' => true
}
```

## Using the Plugin

The plugin adds a new sub record to Accessions, Resources, Archival Objects, and Digital Objects.
The new sub record allows staff users to select a type of offensive content and optionally a
clarifying description of why the tag has been applied. Any number of tags can be applied.

If an object has been tagged directly, the plugin adds new data to the accordion section in the 
PUI which lists out the tags applied and the custom  description if added. A generic description 
is applied if no custom description is available.

In addition, the plugin adds warning tags just under the title of the object which, when clicked,
will open the accordion section and scroll to the offensive content section.

If an object has not been tagged directly, the plugin checks to see if any ancestors have had any
tags applied and adds a set of inherited warning tags just under the title of the object prefixed
with text indicating where the tag(s) where inherited from.

Example: `Applied at the Series level: {TAG}`

The PDF exports have also been modified to include the directly applied tags.

## Reports

The plugin adds an additional report that gathers information about the offensive tags applied. The
report includes the tag and any associated primary type (resource, accession, archival object, 
and digital object).

## PUI Note

This plugin overrides

    /public/views/pdf/_resource.html.erb
    /public/views/pdf/_archival_object.html.erb
    /public/views/shared/_record_innards.html.erb
    
If you are using other plugins which override the same files, you will need to reconcile
them.

## Credits

Plugin developed by Joshua Shaw [Joshua.D.Shaw@dartmouth.edu], Digital Library Technologies Group
Dartmouth Library, Dartmouth College
