-- Goal / plan cover photos.

alter table public.plans
  add column if not exists image_url text;

comment on column public.plans.image_url is
  'Public URL of goal image in storage bucket receipts';
