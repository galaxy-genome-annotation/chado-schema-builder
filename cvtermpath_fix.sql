--- example: select * from fill_cvtermpath(7); where 7 is cv_id for an ontology
--- fill path from the node to its children and their children

--- Also a bugfix backported from https://github.com/GMOD/Chado/pull/105

SELECT set_config('search_path',
  string_agg(quote_ident(s),','),
  false)
FROM unnest(current_schemas(false)) s;

CREATE OR REPLACE FUNCTION _fill_cvtermpath4node(BIGINT, BIGINT, BIGINT, BIGINT, INTEGER, BIGINT[]) RETURNS INTEGER AS
'
DECLARE
    origin alias for $1;
    child_id alias for $2;
    cvid alias for $3;
    typeid alias for $4;
    depth alias for $5;
    forbidden_rels alias for $6;
    cterm cvterm_relationship%ROWTYPE;
    exist_c int;

BEGIN

    --- RAISE NOTICE ''depth=% root=%'', depth,child_id;
    --- not check type_id as it may be null and not very meaningful in cvtermpath when pathdistance > 1
    SELECT INTO exist_c count(*) FROM cvtermpath WHERE cv_id = cvid AND object_id = origin AND subject_id = child_id AND pathdistance = depth;

    IF (exist_c = 0) THEN
        INSERT INTO cvtermpath (object_id, subject_id, cv_id, type_id, pathdistance) VALUES(origin, child_id, cvid, typeid, depth);
    END IF;
    FOR cterm IN SELECT * FROM cvterm_relationship WHERE object_id = child_id and type_id <> ALL(forbidden_rels) LOOP
        PERFORM _fill_cvtermpath4node(origin, cterm.subject_id, cvid, cterm.type_id, depth+1, forbidden_rels);
    END LOOP;
    RETURN 1;
END;
'
LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION _fill_cvtermpath4root(BIGINT, BIGINT, BIGINT[]) RETURNS INTEGER AS
'
DECLARE
    rootid alias for $1;
    cvid alias for $2;
    forbidden_rels alias for $3;
    ttype bigint;
    cterm cvterm_relationship%ROWTYPE;
    child cvterm_relationship%ROWTYPE;

BEGIN

    SELECT INTO ttype cvterm_id FROM cvterm WHERE (name = ''isa'' OR name = ''is_a'');
    PERFORM _fill_cvtermpath4node(rootid, rootid, cvid, ttype, 0, forbidden_rels);
    FOR cterm IN SELECT * FROM cvterm_relationship WHERE object_id = rootid and type_id <> ALL(forbidden_rels) LOOP
        PERFORM _fill_cvtermpath4root(cterm.subject_id, cvid, forbidden_rels);
        -- RAISE NOTICE ''DONE for term, %'', cterm.subject_id;
    END LOOP;
    RETURN 1;
END;
'
LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION fill_cvtermpath(BIGINT) RETURNS INTEGER AS
'
DECLARE
    cvid alias for $1;
    root cvterm%ROWTYPE;
    forbidden_rels bigint[];

BEGIN

    DELETE FROM cvtermpath WHERE cv_id = cvid;

    SELECT INTO forbidden_rels array(SELECT cvterm_id FROM cvterm WHERE (name = ''HAS_PART'' OR name = ''has_part'' OR name = ''preceded_by'' OR name = ''PRECEDED_BY''));

    FOR root IN SELECT DISTINCT t.* from cvterm t LEFT JOIN cvterm_relationship r ON (t.cvterm_id = r.subject_id) INNER JOIN cvterm_relationship r2 ON (t.cvterm_id = r2.object_id) WHERE t.cv_id = cvid AND r.subject_id is null LOOP
        PERFORM _fill_cvtermpath4root(root.cvterm_id, root.cv_id, forbidden_rels);
    END LOOP;
    RETURN 1;
END;
'
LANGUAGE 'plpgsql' SET SEARCH_PATH FROM CURRENT;

CREATE OR REPLACE FUNCTION fill_cvtermpath(cv.name%TYPE) RETURNS INTEGER AS
'
DECLARE
    cvname alias for $1;
    cv_id   int;
    rtn     int;
BEGIN
    SELECT INTO cv_id cv.cv_id from cv WHERE cv.name = cvname;
    SELECT INTO rtn fill_cvtermpath(cv_id);
    RETURN rtn;
END;
'
LANGUAGE 'plpgsql' SET SEARCH_PATH FROM CURRENT;

CREATE OR REPLACE FUNCTION boxrange (bigint, bigint) RETURNS box AS
 'SELECT box (create_point(CAST(0 AS bigint), $1), create_point($2,500000000))'
LANGUAGE 'sql' IMMUTABLE SET SEARCH_PATH FROM CURRENT;

CREATE OR REPLACE FUNCTION boxrange (bigint, bigint, bigint) RETURNS box AS
 'SELECT box (create_point($1, $2), create_point($1,$3))'
LANGUAGE 'sql' IMMUTABLE SET SEARCH_PATH FROM CURRENT;
