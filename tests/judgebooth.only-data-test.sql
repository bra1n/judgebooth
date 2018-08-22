-- phpMyAdmin SQL Dump
-- version 4.5.4.1deb2ubuntu2
-- http://www.phpmyadmin.net
--
-- Host: localhost
-- Generation Time: Dec 16, 2016 at 03:31 PM
-- Server version: 5.7.16-0ubuntu0.16.04.1
-- PHP Version: 7.0.8-0ubuntu0.16.04.3

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
SET AUTOCOMMIT = 0;
START TRANSACTION;
SET time_zone = "+00:00";

DROP TABLE IF EXISTS question_translations;
DROP TABLE IF EXISTS question_cards;
DROP TABLE IF EXISTS questions;
DROP TABLE IF EXISTS users;


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `judgebooth`
--

CREATE TABLE IF NOT EXISTS `questions` (
  `id` int(11) UNSIGNED NOT NULL AUTO_INCREMENT,
  `live` tinyint(1) NOT NULL DEFAULT '0',
  `author` varchar(255) DEFAULT NULL,
  `difficulty` tinyint(1) NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=483 DEFAULT CHARSET=utf8;

--
-- RELATIONS FOR TABLE `questions`:
--

--
-- Dumping data for table `questions`
--

INSERT INTO `questions` (`id`, `live`, `author`, `difficulty`) VALUES
(58, 1, '', 2);

-- --------------------------------------------------------

--
-- Table structure for table `question_cards`
--

CREATE TABLE IF NOT EXISTS `question_cards` (
  `question_id` int(11) UNSIGNED NOT NULL,
  `card_id` int(11) UNSIGNED NOT NULL,
  `sort` tinyint(2) UNSIGNED NOT NULL DEFAULT '0',
  UNIQUE KEY `question_id` (`question_id`,`card_id`,`sort`),
  KEY `card_id` (`card_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- RELATIONS FOR TABLE `question_cards`:
--   `question_id`
--       `questions` -> `id`
--   `card_id`
--       `cards` -> `id`
--

--
-- Dumping data for table `question_cards`
--

INSERT INTO `question_cards` (`question_id`, `card_id`, `sort`) VALUES
(58, 2827, 0),
(58, 3384, 0),
(58, 4187, 0),
(58, 4202, 0),
(58, 8122, 0);

-- --------------------------------------------------------

--
-- Table structure for table `question_translations`
--

CREATE TABLE IF NOT EXISTS `question_translations` (
  `question_id` int(11) UNSIGNED NOT NULL,
  `language_id` int(11) UNSIGNED NOT NULL,
  `question` text NOT NULL,
  `answer` text NOT NULL,
  `changedate` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY `question_id` (`question_id`,`language_id`),
  KEY `language_id` (`language_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- RELATIONS FOR TABLE `question_translations`:
--   `question_id`
--       `questions` -> `id`
--   `language_id`
--       `languages` -> `id`
--

--
-- Dumping data for table `question_translations`
--

INSERT INTO `question_translations` (`question_id`, `language_id`, `question`, `answer`, `changedate`) VALUES
(58, 1, 'With Pandemonium, Humility, Copy Enchantment, and Opalescence in the graveyard, I cast Replenish. What\'s the highest amount of damage that I could deal?', '0 Damage. Copy Enchantment can\'t copy anything that enters the battlefield at the same time as it does. Pandemonium does not have any ability, because of Humility and Opalescence.', '2015-05-21 18:39:53'),
(58, 2, 'Während ich Pandämonium, Humility, Verzauberungskopie und Opalessenz auf meinem Firedhof habe, wirke ich Replenish. Wie hoch ist die größte Anzahl an Schaden, die ich zufügen könnte?', '0 Schaden. Die Verzauberungskopie kann nichts kopieren, das gleichzeitig mit ihr das Schlachtfeld betritt. Pandämonium hat keine Fähigkeiten, da sie von Opalessenz und Humility betroffen ist.', '2015-06-04 12:07:33'),
(58, 4, '《伏魔殿／Pandemonium》[TSB]、《エンチャント複製／Copy Enchantment》[RAV]、《謙虚／Humility》[TMP]、《オパール色の輝き／Opalescence》[UDS]が墓地にある状態で《補充／Replenish》[UDS]を唱えました。与えられることのできる最大のダメージは何点ですか？', '０点。《エンチャント複製》は同時に戦場にでるエンチャントのコピーになることはできません。《謙虚》と《オパール色の輝き》があるので、《伏魔殿》は全ての能力を失っています。', '2015-11-18 04:29:52'),
(58, 6, 'Com Pandemônio, Humility, Cópia de Encantamento e Opalescence no cemitério, eu conjuro Replenish. Qual é o máximo de dano que eu consigo dar?', '0 de dano. Cópia de Encantamento não pode copiar nada que entra no campo de batalha ao mesmo tempo que ela. Pandemônio não tem nenhuma habilidade devido a Humility e Opalescence.', '2016-05-30 15:26:45'),
(58, 7, 'У меня на кладбище Столпотворение, Humility, Копия Чар и Opalescence. Я разыгрываю Replenish. Какое максимальное количество поверждений я могу нанести?', '0 повреждений. Копия Чар не может копировать то, что входит на поле битвы в тот же момент. У Столпотворения нет способностей из-за Opalescence и Humility.', '2015-05-21 18:40:02'),
(58, 8, 'Con Pandemónium, Humildad, Encantamiento Copia y Opalescencia en el cementerio lanzo Reabastecer , ¿Cuál es la mayor cantidad de daño que podría hacer?', '0 daño. Encantamiento Copia no puede copiar nada que entre al campo de batalla al mismo tiempo. Pandemónium no tiene ninguna habilidad debido a Humildad y Opalescencia.', '2015-11-25 15:37:08'),
(58, 9, '我的坟墓场里有大混乱、谦卑、复制结界和蛋白石光辉，我施放充盈。请问我最多能造成多少点伤害？', '0点。复制结界不能复制与其同时进入战场的其他结界。由于谦卑和蛋白石光辉，大混乱没有异能。', '2015-05-21 18:39:59'),
(58, 10, '我的墳墓場裡有大混亂/Pandemonium、謙卑/Humility、複製結界/Copy Enchantment和蛋白石光輝/Opalescence，我施放充盈/Replenish。請問我最多能造成多少點傷害？', '0點。複製結界不能複製與其同時進入戰場的其他結界。由於謙卑和蛋白石光輝，大混亂沒有異能。', '2015-05-21 18:40:00'),
(58, 11, 'Avec Pandémonium, Humility, Copie d\'enchantement et Opalescence dans le cimetière, je lance Replenish. Combien de blessures au maximum puis-je infliger ?', '0 blessure. La Copie d\'enchantement ne peut pas copier quelque chose qui arrive sur le champ de bataille en même temps qu\'elle. Pandémonium n\'a aucune capacité, à cause d\'Humility et Opalescence.', '2015-10-21 18:43:51');

-- --------------------------------------------------------

--
-- Table structure for table `sets`
--

CREATE TABLE IF NOT EXISTS `sets` (
  `id` int(11) UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL DEFAULT '',
  `code` varchar(8) DEFAULT NULL,
  `releasedate` datetime DEFAULT NULL,
  `regular` tinyint(1) NOT NULL DEFAULT '1',
  `standard` tinyint(1) NOT NULL DEFAULT '1',
  `modern` tinyint(1) NOT NULL DEFAULT '1',
  `legacy` tinyint(1) NOT NULL DEFAULT '1',
  PRIMARY KEY (`id`),
  UNIQUE KEY `name` (`name`)
) ENGINE=InnoDB AUTO_INCREMENT=24215 DEFAULT CHARSET=utf8;

--
-- Table structure for table `users`
--

CREATE TABLE IF NOT EXISTS `users` (
  `name` varchar(255) NOT NULL,
  `email` varchar(255) NOT NULL,
  `role` varchar(50) NOT NULL,
  `languages` varchar(255) NOT NULL,
  UNIQUE KEY `email` (`email`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- RELATIONS FOR TABLE `users`:
--

--
-- Dumping data for table `users`
--

INSERT INTO `users` (`name`, `email`, `role`, `languages`) VALUES
('Admin Istrator', 'boothadmin@gmail.com', 'admin', '');

--
-- Constraints for dumped tables
--

--
-- Constraints for table `question_cards`
--
ALTER TABLE `question_cards`
  ADD CONSTRAINT `question_cards_ibfk_1` FOREIGN KEY (`question_id`) REFERENCES `questions` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `question_cards_ibfk_2` FOREIGN KEY (`card_id`) REFERENCES `cards` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `question_translations`
--
ALTER TABLE `question_translations`
  ADD CONSTRAINT `question_translations_ibfk_1` FOREIGN KEY (`question_id`) REFERENCES `questions` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `question_translations_ibfk_2` FOREIGN KEY (`language_id`) REFERENCES `languages` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
