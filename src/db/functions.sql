-- Create or get user
CREATE OR REPLACE FUNCTION p_add_or_get_user (_pm_email varchar, _pm_first_name varchar, _pm_last_name varchar, _pm_fb_id bigint, _pm_gender varchar, _pm_timezone numeric)
  RETURNS TABLE( user_id integer ) AS
$BODY$
  DECLARE _v_user_id integer;
  BEGIN
    SELECT id INTO _v_user_id FROM syn_user WHERE email = _pm_email;
    IF _v_user_id IS NULL THEN
      INSERT INTO syn_user (email, first_name, last_name, fb_id, gender, timezone) VALUES
        (_pm_email, _pm_first_name, _pm_last_name, _pm_fb_id, _pm_gender, _pm_timezone)
      RETURNING id INTO _v_user_id;
    ELSE
      UPDATE syn_user SET softtime = CURRENT_TIMESTAMP WHERE id = _v_user_id;
    END IF;
    RETURN QUERY SELECT _v_user_id;
  END;
$BODY$
  LANGUAGE plpgsql VOLATILE;
