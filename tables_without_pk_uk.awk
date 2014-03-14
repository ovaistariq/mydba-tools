
# This can be used with the schema dump file created by mysqldump
# Typical mysqldump invocation would be as below:
#  mysqldump --no-data --all-databases --skip-opt --compact --create-options > db_schema.sql
# And then: awk -f tables_without_pk.awk db_schema.sql

BEGIN {
        is_create_table_start=0;
        has_pk=0;
        has_uk=0;
        table_name="none";
        db_name="none";
}

/CREATE DATABASE/ {
        db_name=$7;
}

/CREATE TABLE/ {
        if (table_name != "none" && has_pk == 0 && has_uk == 0) {
                print db_name"."table_name;
        }

        table_name=$3;
        has_pk=0;
}

/PRIMARY KEY/ {
        has_pk=1;
}

/UNIQUE KEY/ {
        has_uk=1;
}

