-- phpMyAdmin SQL Dump
-- version 4.0.10deb1
-- http://www.phpmyadmin.net
--
-- Host: localhost
-- Erstellungszeit: 13. Mai 2015 um 19:23
-- Server Version: 5.5.43-0ubuntu0.14.04.1
-- PHP-Version: 5.5.9-1ubuntu4.9

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
SET AUTOCOMMIT = 0;
START TRANSACTION;
SET time_zone = "+00:00";

--
-- Datenbank: `judgebooth`
--

-- --------------------------------------------------------

--
-- Tabellenstruktur für Tabelle `card_sets`
--

CREATE TABLE IF NOT EXISTS `card_sets` (
  `card_id` int(11) unsigned NOT NULL,
  `set_id` int(11) unsigned NOT NULL,
  UNIQUE KEY `card_id` (`card_id`,`set_id`),
  KEY `set_id` (`set_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Tabellenstruktur für Tabelle `card_translations`
--

CREATE TABLE IF NOT EXISTS `card_translations` (
  `card_id` int(11) unsigned NOT NULL,
  `language_id` int(11) unsigned NOT NULL,
  `name` varchar(255) NOT NULL DEFAULT '',
  UNIQUE KEY `card_id` (`card_id`,`language_id`),
  KEY `language_id` (`language_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Tabellenstruktur für Tabelle `cards`
--

CREATE TABLE IF NOT EXISTS `cards` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL DEFAULT '',
  `full_name` varchar(255) DEFAULT NULL,
  `layout` varchar(20) DEFAULT NULL,
  `manacost` varchar(128) DEFAULT NULL,
  `type` varchar(128) DEFAULT NULL,
  `text` text,
  `power` varchar(3) DEFAULT NULL,
  `toughness` varchar(3) DEFAULT NULL,
  `loyalty` varchar(2) DEFAULT NULL,
  `url` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `name` (`name`)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Tabellenstruktur für Tabelle `languages`
--

CREATE TABLE IF NOT EXISTS `languages` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL DEFAULT '',
  `code` varchar(2) NOT NULL DEFAULT '',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8;

--
-- Daten für Tabelle `languages`
--

INSERT INTO `languages` (`id`, `name`, `code`) VALUES
(1, 'English', 'en'),
(2, 'German', 'de'),
(3, 'Italian', 'it'),
(4, 'Japanese', 'jp'),
(5, 'Korean', 'ko'),
(6, 'Portuguese (Brazil)', 'pt'),
(7, 'Russian', 'ru'),
(8, 'Spanish', 'es'),
(9, 'Chinese Simplified', 'cn'),
(10, 'Chinese Traditional', 'tw'),
(11, 'French', 'fr');

-- --------------------------------------------------------

--
-- Tabellenstruktur für Tabelle `question_cards`
--

CREATE TABLE IF NOT EXISTS `question_cards` (
  `question_id` int(11) unsigned NOT NULL,
  `card_id` int(11) unsigned NOT NULL,
  UNIQUE KEY `question_id` (`question_id`,`card_id`),
  KEY `card_id` (`card_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Tabellenstruktur für Tabelle `question_translations`
--

CREATE TABLE IF NOT EXISTS `question_translations` (
  `question_id` int(11) unsigned NOT NULL,
  `language_id` int(11) unsigned NOT NULL,
  `question` text NOT NULL,
  `answer` text NOT NULL,
  `changedate` timestamp NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY `question_id` (`question_id`,`language_id`),
  KEY `language_id` (`language_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Tabellenstruktur für Tabelle `questions`
--

CREATE TABLE IF NOT EXISTS `questions` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `live` tinyint(1) NOT NULL DEFAULT '0',
  `author` varchar(255) DEFAULT NULL,
  `difficulty` tinyint(1) NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Tabellenstruktur für Tabelle `sets`
--

CREATE TABLE IF NOT EXISTS `sets` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL DEFAULT '',
  `code` varchar(5) DEFAULT NULL,
  `releasedate` datetime DEFAULT NULL,
  `regular` tinyint(1) NOT NULL DEFAULT '1',
  `standard` tinyint(1) NOT NULL DEFAULT '1',
  `modern` tinyint(1) NOT NULL DEFAULT '1',
  `legacy` tinyint(1) NOT NULL DEFAULT '1',
  PRIMARY KEY (`id`),
  UNIQUE KEY `name` (`name`)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Tabellenstruktur für Tabelle `users`
--

CREATE TABLE IF NOT EXISTS `users` (
  `name` varchar(255) NOT NULL,
  `email` varchar(255) NOT NULL,
  `role` varchar(50) NOT NULL,
  `language_id` int(11) unsigned DEFAULT NULL,
  UNIQUE KEY `name` (`name`),
  UNIQUE KEY `language_id` (`language_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Constraints der exportierten Tabellen
--

--
-- Constraints der Tabelle `card_sets`
--
ALTER TABLE `card_sets`
  ADD CONSTRAINT `card_sets_ibfk_1` FOREIGN KEY (`card_id`) REFERENCES `cards` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `card_sets_ibfk_2` FOREIGN KEY (`set_id`) REFERENCES `sets` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints der Tabelle `card_translations`
--
ALTER TABLE `card_translations`
  ADD CONSTRAINT `card_translations_ibfk_1` FOREIGN KEY (`card_id`) REFERENCES `cards` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `card_translations_ibfk_2` FOREIGN KEY (`language_id`) REFERENCES `languages` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints der Tabelle `question_cards`
--
ALTER TABLE `question_cards`
  ADD CONSTRAINT `question_cards_ibfk_1` FOREIGN KEY (`question_id`) REFERENCES `questions` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `question_cards_ibfk_2` FOREIGN KEY (`card_id`) REFERENCES `cards` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints der Tabelle `question_translations`
--
ALTER TABLE `question_translations`
  ADD CONSTRAINT `question_translations_ibfk_1` FOREIGN KEY (`question_id`) REFERENCES `questions` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `question_translations_ibfk_2` FOREIGN KEY (`language_id`) REFERENCES `languages` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints der Tabelle `users`
--
ALTER TABLE `users`
  ADD CONSTRAINT `users_ibfk_1` FOREIGN KEY (`language_id`) REFERENCES `languages` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;
COMMIT;
