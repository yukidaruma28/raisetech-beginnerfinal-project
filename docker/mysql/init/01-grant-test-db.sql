-- inquiry ユーザーに inquiry_tracker_test 含む inquiry_tracker* 系 DB の権限を付与
-- MYSQL_USER は MYSQL_DATABASE (inquiry_tracker) にしか自動でアクセス権を持たないため、
-- Rails の db:prepare が test DB を作成・接続できるよう明示的に GRANT する
GRANT ALL PRIVILEGES ON `inquiry_tracker%`.* TO 'inquiry'@'%';
FLUSH PRIVILEGES;
