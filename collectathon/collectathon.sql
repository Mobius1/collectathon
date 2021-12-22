DROP TABLE IF EXISTS `user_collectables`;

CREATE TABLE `user_collectables` (
  `identifier` varchar(50) NOT NULL,
  `collected` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

ALTER TABLE `user_collectables` ADD PRIMARY KEY (`identifier`);
