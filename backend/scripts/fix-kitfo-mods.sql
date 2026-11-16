UPDATE menu_items
SET modifiers = '[{"id":"mod-injera","name":"Extra injera","priceEtb":40},{"id":"mod-spicy","name":"Extra spicy","priceEtb":0}]'::jsonb
WHERE id = 'i-kitfo';
