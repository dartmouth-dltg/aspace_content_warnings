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
system with a set of Traditonal Knowledge Labels. The controlled value list is editable
should additional TK Labels be defined in future. 

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


## Reports


## PUI Note

This plugin overrides

    
If you are using other plugins which override the same files, you will need to reconcile
them.

## Credits

Plugin developed by Joshua Shaw [Joshua.D.Shaw@dartmouth.edu], Digital Library Technologies Group
Dartmouth Library, Dartmouth College
