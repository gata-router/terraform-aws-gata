CREATE EXTENSION vector;

CREATE TYPE router AS ENUM ('external', 'gata', 'gata-mapped');
CREATE TYPE channel AS ENUM (
  'answer_bot_api',
  'answer_bot_for_agents',
  'answer_bot_for_sdk',
  'answer_bot_for_slack',
  'answer_bot_for_web_widget',
  'any_channel',
  'api',
  'apple_business_chat',
  'business_messaging_slack_connect',
  'chat',
  'chat_transcript',
  'email',
  'facebook',
  'forum',
  'google_business_messages',
  'google_rcs',
  'help_center',
  'instagram_dm',
  'kakaotalk',
  'line',
  'mailgun',
  'messagebird_sms',
  'mobile',
  'mobile_sdk',
  'native_messaging',
  'rule',
  'sample_ticket',
  'side_conversation',
  'sms',
  'sunshine_conversations_api',
  'sunshine_conversations_facebook_messenger',
  'sunshine_conversations_twitter_dm',
  'telegram',
  'twilio_sms',
  'twitter',
  'viber',
  'voice',
  'web',
  'wechat',
  'whatsapp'
);

CREATE TABLE ticket (
  id integer PRIMARY KEY,
  processed_data text NOT NULL,
  via_channel channel NOT NULL,
  probability real NOT NULL,
  CHECK (probability BETWEEN 0 AND 1),
  routed_by router NOT NULL,
  created integer NOT NULL,
  initial_group_id bigint,
  initial_group_id_mapped bigint,
  closed integer DEFAULT 0,
  closed_group_id bigint,
  closed_group_id_mapped bigint,
  embedding vector(1024) NOT NULL
);

CREATE INDEX ON ticket (via_channel, closed);
CREATE INDEX ON ticket (via_channel, closed_group_id_mapped, closed);

CREATE INDEX ON ticket USING ivfflat (embedding vector_l2_ops) WITH (lists = 100);
CREATE INDEX ON ticket USING ivfflat (embedding vector_ip_ops) WITH (lists = 100);
CREATE INDEX ON ticket USING ivfflat (embedding vector_cosine_ops) WITH (lists = 100);
