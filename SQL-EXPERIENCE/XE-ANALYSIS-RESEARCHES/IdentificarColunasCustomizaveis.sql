/* 
SET { event_customizable_attribute= <value> [ ,...n] }
Allows customizable attributes for the event to be set. Customizable attributes appear in the sys.dm_xe_object_columns view as column_type 'customizable ' and object_name = event_name.
*/
SELECT * FROM sys.dm_xe_object_columns
WHERE object_name = 'object_altered' -- nome do evento estendido


