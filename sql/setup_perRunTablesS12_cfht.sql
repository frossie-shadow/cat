-- LSST Data Management System
-- Copyright 2008, 2009, 2010 LSST Corporation.
--
-- This product includes software developed by the
-- LSST Project (http://www.lsst.org/).
--
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the LSST License Statement and
-- the GNU General Public License along with this program.  If not,
-- see <http://www.lsstcorp.org/LegalNotices/>.


-- One-time setup actions for LSST pipelines - assumes the LSST Database Schema already exists.
-- $Author$
-- $Revision$
-- $Date$
--
-- See <http://lsstdev.ncsa.uiuc.edu/trac/wiki/Copyrights>
-- for copyright information.


-- ================================================= --
--                    Create Views                   --
-- ================================================= --



-- ================================================= --
-- Populate lookup/mapping tables with fixed content --
-- ================================================= --

-- LSST filters
-- INSERT INTO prv_Filter VALUES (0,  0, 'u', NULL, 0.0, 0.0);
-- INSERT INTO prv_Filter VALUES (1,  0, 'g', NULL, 0.0, 0.0);
-- INSERT INTO prv_Filter VALUES (2,  0, 'r', NULL, 0.0, 0.0);
-- INSERT INTO prv_Filter VALUES (3,  0, 'i', NULL, 0.0, 0.0);
-- INSERT INTO prv_Filter VALUES (4,  0, 'z', NULL, 0.0, 0.0);
-- INSERT INTO prv_Filter VALUES (5,  0, 'y', NULL, 0.0, 0.0);
-- Additional filters used by MOPS
-- INSERT INTO prv_Filter VALUES (6,  0, 'w', NULL, 0.0, 0.0);
-- INSERT INTO prv_Filter VALUES (7,  0, 'V', NULL, 0.0, 0.0);
-- INSERT INTO prv_Filter VALUES (-99, 0, 'DD', NULL, 0.0, 0.0); -- dummy filter

INSERT INTO Filter(filterId, filterName, photClam, photBW) VALUES (0,  'u', 0.0, 0.0);
INSERT INTO Filter(filterId, filterName, photClam, photBW) VALUES (1,  'g', 0.0, 0.0);
INSERT INTO Filter(filterId, filterName, photClam, photBW) VALUES (2,  'r', 0.0, 0.0);
INSERT INTO Filter(filterId, filterName, photClam, photBW) VALUES (3,  'i', 0.0, 0.0);
INSERT INTO Filter(filterId, filterName, photClam, photBW) VALUES (4,  'z', 0.0, 0.0);
INSERT INTO Filter(filterId, filterName, photClam, photBW) VALUES (5,  'i2', 0.0, 0.0);
INSERT INTO Filter(filterId, filterName, photClam, photBW) VALUES (-99, 'DD', 0.0, 0.0);


-- ================================================================ --
--                 Load table of leap seconds.                      --
--           Created by K.-T. Lim (ktl@slac.stanford.edu)           --
-- ================================================================ --


INSERT INTO LeapSeconds (whenJd, offset, mjdRef, drift) VALUES
    (2437300.5, 1.4228180, 37300., 0.001296),
    (2437512.5, 1.3728180, 37300., 0.001296),
    (2437665.5, 1.8458580, 37665., 0.0011232),
    (2438334.5, 1.9458580, 37665., 0.0011232),
    (2438395.5, 3.2401300, 38761., 0.001296),
    (2438486.5, 3.3401300, 38761., 0.001296),
    (2438639.5, 3.4401300, 38761., 0.001296),
    (2438761.5, 3.5401300, 38761., 0.001296),
    (2438820.5, 3.6401300, 38761., 0.001296),
    (2438942.5, 3.7401300, 38761., 0.001296),
    (2439004.5, 3.8401300, 38761., 0.001296),
    (2439126.5, 4.3131700, 39126., 0.002592),
    (2439887.5, 4.2131700, 39126., 0.002592),
    (2441317.5, 10.0, 41317., 0.0),
    (2441499.5, 11.0, 41317., 0.0),
    (2441683.5, 12.0, 41317., 0.0),
    (2442048.5, 13.0, 41317., 0.0),
    (2442413.5, 14.0, 41317., 0.0),
    (2442778.5, 15.0, 41317., 0.0),
    (2443144.5, 16.0, 41317., 0.0),
    (2443509.5, 17.0, 41317., 0.0),
    (2443874.5, 18.0, 41317., 0.0),
    (2444239.5, 19.0, 41317., 0.0),
    (2444786.5, 20.0, 41317., 0.0),
    (2445151.5, 21.0, 41317., 0.0),
    (2445516.5, 22.0, 41317., 0.0),
    (2446247.5, 23.0, 41317., 0.0),
    (2447161.5, 24.0, 41317., 0.0),
    (2447892.5, 25.0, 41317., 0.0),
    (2448257.5, 26.0, 41317., 0.0),
    (2448804.5, 27.0, 41317., 0.0),
    (2449169.5, 28.0, 41317., 0.0),
    (2449534.5, 29.0, 41317., 0.0),
    (2450083.5, 30.0, 41317., 0.0),
    (2450630.5, 31.0, 41317., 0.0),
    (2451179.5, 32.0, 41317., 0.0),
    (2453736.5, 33.0, 41317., 0.0),
    (2454832.5, 34.0, 41317., 0.0),
    (2456109.5, 35.0, 41317., 0.0);

UPDATE LeapSeconds
    SET whenMjdUtc = whenJd - 2400000.5,
        whenUtc = CAST((whenMjdUtc - 40587.0) * 86.4e12 AS SIGNED),
        whenTai = whenUtc +
            CAST(1.0e9 * (offset + (whenMjdUtc - mjdRef) * drift) AS SIGNED);



-- ================================================================ --
--  Create tables using existing templates, adjust engine types etc --
-- ================================================================ --

-- This is to speed up ingest of log messages during pipeline execution
ALTER TABLE Logs DISABLE KEYS;

-- CREATE TABLE DiaSourceForMovingObject LIKE DiaSource;


-- CREATE TABLE _tmpl_DiaSource LIKE DiaSource;

-- ALTER TABLE _tmpl_DiaSource
--     DROP KEY ccdExposureId,
--     DROP KEY filterId,
--     DROP KEY movingObjectId,
--     DROP KEY objectId;

-- This should be a permanent table, but copy it from Object for now.
-- CREATE TABLE NonVarObject LIKE Object;

-- CREATE TABLE _tmpl_InMemoryObject LIKE Object;

-- ALTER TABLE _tmpl_InMemoryObject ENGINE=MEMORY;

-- CREATE TABLE _tmpl_InMemoryMatchPair LIKE _tmpl_MatchPair;
-- ALTER TABLE _tmpl_InMemoryMatchPair ENGINE=MEMORY;

-- CREATE TABLE _tmpl_InMemoryId LIKE _tmpl_Id;
-- ALTER TABLE _tmpl_InMemoryId ENGINE=MEMORY;

-- Create tables that accumulate data from per-visit tables
-- CREATE TABLE _mops_Prediction LIKE _tmpl_mops_Prediction;
-- ALTER TABLE _mops_Prediction
--     ADD COLUMN visitId INTEGER NOT NULL,
--     ADD INDEX  idx_visitId (visitId);

-- CREATE TABLE _ap_DiaSourceToObjectMatches LIKE _tmpl_MatchPair;
-- ALTER TABLE _ap_DiaSourceToObjectMatches
--     ADD COLUMN visitId INTEGER NOT NULL,
--     ADD INDEX  idx_visitId (visitId);

-- CREATE TABLE _ap_PredToDiaSourceMatches LIKE _tmpl_MatchPair;
-- ALTER TABLE _ap_PredToDiaSourceMatches
--     ADD COLUMN visitId INTEGER NOT NULL,
--     ADD INDEX  idx_visitId (visitId);

-- CREATE TABLE _ap_DiaSourceToNewObject LIKE _tmpl_IdPair;
-- ALTER TABLE _ap_DiaSourceToNewObject
--     ADD COLUMN visitId INTEGER NOT NULL,
--     ADD INDEX  idx_visitId (visitId);

-- CREATE TABLE BadSource LIKE Source;

