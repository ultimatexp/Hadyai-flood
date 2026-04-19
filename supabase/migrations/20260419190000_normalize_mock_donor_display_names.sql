-- Strip leading คุณ from seed mock rows so app labels match bundled mock avatars.
update public.donations
set display_name = regexp_replace(trim(coalesce(display_name, '')), '^คุณ', '')
where stripe_checkout_session_id like 'cs_test_mock_seed_%'
  and coalesce(display_name, '') like 'คุณ%';
