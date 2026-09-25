-- ====================================================================
-- Crop Disease & Pest Management Database (disease_database.sql)
-- Complete Dataset: All 21 Records with Fully Populated Child Tables
-- ====================================================================

-- CREATE DATABASE IF NOT EXISTS crop_disease_db;
-- USE crop_disease_db;

-- 1. Crops Table
CREATE TABLE IF NOT EXISTS crops (
    crop_id VARCHAR(50) PRIMARY KEY,
    crop_name VARCHAR(100) NOT NULL
);

-- 2. Diseases Table
CREATE TABLE IF NOT EXISTS diseases (
    disease_id VARCHAR(100) PRIMARY KEY,
    crop_id VARCHAR(50) NOT NULL,
    disease_name VARCHAR(255) NOT NULL,
    scientific_name_or_pathogen TEXT,
    description TEXT,
    cause TEXT,
    severity TEXT,
    farmer_action TEXT,
    FOREIGN KEY (crop_id) REFERENCES crops(crop_id)
);

-- 3. Symptoms Table
CREATE TABLE IF NOT EXISTS disease_symptoms (
    id SERIAL PRIMARY KEY,
    disease_id VARCHAR(100) NOT NULL,
    symptom_text TEXT NOT NULL,
    FOREIGN KEY (disease_id) REFERENCES diseases(disease_id) ON DELETE CASCADE
);

-- 4. Healthy Signs Table (for healthy records)
CREATE TABLE IF NOT EXISTS healthy_signs (
    id SERIAL PRIMARY KEY,
    disease_id VARCHAR(100) NOT NULL,
    sign_text TEXT NOT NULL,
    FOREIGN KEY (disease_id) REFERENCES diseases(disease_id) ON DELETE CASCADE
);

-- 5. Favorable Conditions Table
CREATE TABLE IF NOT EXISTS favorable_conditions (
    id SERIAL PRIMARY KEY,
    disease_id VARCHAR(100) NOT NULL,
    condition_text TEXT NOT NULL,
    FOREIGN KEY (disease_id) REFERENCES diseases(disease_id) ON DELETE CASCADE
);

-- 6. Treatments Table
CREATE TABLE IF NOT EXISTS treatments (
    id SERIAL PRIMARY KEY,
    disease_id VARCHAR(100) NOT NULL,
    category VARCHAR(50) NOT NULL,
    treatment_text TEXT NOT NULL,
    FOREIGN KEY (disease_id) REFERENCES diseases(disease_id) ON DELETE CASCADE
);

-- 7. Prevention Table
CREATE TABLE IF NOT EXISTS prevention_steps (
    id SERIAL PRIMARY KEY,
    disease_id VARCHAR(100) NOT NULL,
    prevention_text TEXT NOT NULL,
    FOREIGN KEY (disease_id) REFERENCES diseases(disease_id) ON DELETE CASCADE
);

-- 8. Sources Table
CREATE TABLE IF NOT EXISTS sources (
    id SERIAL PRIMARY KEY,
    disease_id VARCHAR(100) NOT NULL,
    title VARCHAR(255) NOT NULL,
    organization VARCHAR(255),
    url TEXT,
    FOREIGN KEY (disease_id) REFERENCES diseases(disease_id) ON DELETE CASCADE
);

-- ====================================================================
-- Initial Crop Inserts
-- ====================================================================
INSERT INTO crops (crop_id, crop_name) VALUES 
('apple', 'Apple'),
('maize', 'Maize'),
('potato', 'Potato'),
('tomato', 'Tomato');

-- ====================================================================
-- Disease Master Records (All 21 Diseases)
-- ====================================================================
INSERT INTO diseases (disease_id, crop_id, disease_name, scientific_name_or_pathogen, description, cause, severity, farmer_action) VALUES
('apple_scab', 'apple', 'Apple Scab', 'Venturia inaequalis', 'Apple scab is the most destructive fungal disease of apple, attacking leaves, shoots and fruit. It causes olive-green to dark scab-like spots, early leaf fall and cracked, deformed, unmarketable fruit.', 'The fungus overwinters in fallen infected leaves on the orchard floor. In cool, rainy spring weather it releases spores carried by wind and rain-splash onto newly emerging leaves and fruit; repeated secondary infections then spread during wet spells.', 'potentially severe - the world''s most important apple disease; on susceptible varieties in a wet spring it causes defoliation and fruit cracking with heavy yield and fruit-quality loss', 'Rake up and destroy/compost fallen infected leaves and fruit, and start the state-recommended spray schedule (e.g., mancozeb or captan at silver-tip-green-tip, repeated at 12-14 day intervals in scab-prone orchards), covering the whole canopy thoroughly.'),

('apple_black_rot', 'apple', 'Apple Black Rot (Black Rot of Fruit / Frogeye Leaf Spot)', 'Botryosphaeria obtusa (asexual stage: Diplodia seriata)', 'Black rot is a fungal disease that occurs in three forms: ''frogeye'' leaf spot, a firm black rot of fruit (often starting at the blossom end), and cankers on branches and trunk. Rotted fruit dry out into shrivelled black mummies and can weaken trees by early leaf fall.', 'The fungus overwinters in cankers, dead wood and mummified fruit. In wet weather spores are spread by splashing rain, wind and insects and enter through wounds, natural openings or the open calyx tube. Warm, wet conditions and stressed trees (cold injury, drought, fire blight damage) favour infection.', 'moderate - mainly reduces fruit quality, marketability and tree vigour; losses can be significant when trees are stressed, fire blight is present or the season is wet and warm', 'Remove every shrivelled ''mummy'' fruit and prune out dead/cankered wood (burn or bury the prunings), control fire blight, and keep trees vigorous with adequate water - fungicide is usually secondary to this sanitation.'),

('apple_cedar_apple_rust', 'apple', 'Apple Cedar-Apple Rust', 'Gymnosporangium juniperi-virginianae', 'Cedar-apple rust is a fungal disease that needs TWO host plants to live: apple (and crabapple) plus cedar/juniper trees. On apple it causes bright yellow-orange spots on leaves and blistered patches on fruit, plus early leaf fall. It is primarily a North American disease, and no reliable Indian source was found.', 'The rust has a two-year life cycle on two hosts: spores from cedar/juniper galls are wind-carried to apple leaves and fruit during spring rains, and spores formed on apple later infect cedar/juniper. Spores from apple do not re-infect apple, so there is no secondary cycle on apple. Geographic note: mainly recorded in eastern North America; rare/little-documented in India.', 'moderate - can defoliate trees and blemish fruit where juniper hosts are close, but it is primarily a North American disease of limited documented relevance in India', 'Where cedar/juniper plants stand near the orchard, remove them or cut off the round woody galls before spring; in India, treat this as a rare/foreign issue and confirm any orange-spot diagnosis through the local KVK/extension before spending on sprays.'),

('apple_healthy', 'apple', 'Healthy Apple Tree (Normal / Disease-free condition)', NULL, 'A healthy apple tree has clean, uniform green leaves without spots, well-formed fruits with smooth skin, and vigorous shoots with no dieback, cankers, mummies or pest damage. Indian apples are mainly grown in Kashmir (about 80% of national production), Himachal Pradesh, Uttarakhand and the higher hills of other states.', NULL, NULL, 'Walk the orchard every week from bud-break to harvest: check leaves, trunks and fruit for any spot, mummy, ooze or pest; remove and destroy anything infected immediately, keep the orchard floor clean, and follow the state-recommended spray-and-nutrition calendar through the KVK or Department of Horticulture.'),

('corn_gray_leaf_spot', 'maize', 'Grey / Gray Leaf Spot (Cercospora Leaf Spot)', 'Cercospora zeae-maydis / Cercospora zeina', 'A foliar fungal disease of maize that destroys green leaf tissue and can cut grain yield, especially in warm, humid weather and where maize follows maize with residue left on the soil surface. It is one of the most important foliar diseases of corn where it is established.', 'The fungus survives between seasons on infected maize residue (stubble) left on the soil surface, where it produces spores spread to new leaves by wind splash and air currents. It favours long periods of high humidity and kills leaf tissue, so the plant has less green area to fill grain.', 'potentially severe - repeatedly described as one of the most damaging foliar diseases of maize where established, with reported yield loss of up to 15-50% when most leaf area is destroyed before grain fill', 'Walk the field during a humid spell and strip-check the lower leaves: if rectangular grey ''block''-shaped lesions running between the veins are present on several plants near tasseling/silking, spray once with a product labelled for maize grey leaf spot at the label rate and confirm the dose with your local agriculture department/KVK, then bury or remove residue after harvest.'),

('corn_common_rust', 'maize', 'Common Rust of Maize', 'Puccinia sorghi', 'A wind-borne rust disease of maize that forms powdery cinnamon-brown pustules, mainly on leaves. It is a major foliar disease of maize in India and is favoured by cool, moist weather (about 15-25 C). On susceptible sweet corn it can cause substantial loss; on field maize damage is usually more limited but can still cut yield in cool humid seasons.', 'Puccinia sorghi is a heteroecious rust: part of its life cycle needs Oxalis (wood sorrel) weeds as an alternate host, and spores produced there are carried by wind to infect maize. On maize it multiplies as airborne uredospores on live leaves, repeating infection cycles, favoured by cool, damp weather around 15-25 C.', 'moderate - usually limited on field maize but can flare up in cool, humid seasons; Indian field trials show effective control of common rust significantly improved yield', 'In cool, damp spells, inspect both leaf sides for powdery cinnamon-brown pustules; if pustules are seen before or around tasseling, spray tebuconazole (~1 ml/L) or kresoxim-methyl 44.3% SC (~1 ml/L) at 35 and 50 days after sowing (TNAU), and clear Oxalis weeds from the field and bunds.'),

('corn_northern_leaf_blight', 'maize', 'Turcicum / Northern Corn Leaf Blight (long cigar-shaped leaf blight)', 'Exserohilum turcicum', 'One of the most important fungal leaf diseases of maize in India, present in virtually all maize-growing regions in both kharif and rabi. It forms long, cigar-shaped leaf lesions that can ''burn'' the whole foliage, and causes significant yield loss when infection starts around the silking stage.', 'The fungus survives on infected maize stubble and plant debris, where conidia and thick-walled chlamydospores carry it over between seasons. Wind-blown spores infect leaves in wet, humid, cool weather, and multiple infection cycles destroy the green leaf tissue the plant needs to fill grain.', 'potentially severe - a major, yield-limiting disease of maize in India in both kharif and rabi, with significant loss when infection begins around silking', 'Scout the lower leaves during humid spells for long cigar-shaped, tapering lesions; on first appearance spray mancozeb or zineb @ 2-4 g/L (or propiconazole 25% EC @ 1 ml/L) at 35 and 50 days after sowing as per TNAU, and burn or bury infected stubble after harvest.'),

('corn_healthy', 'maize', 'Healthy Maize (no disease)', NULL, 'A maize plant showing none of the disease symptoms described for the leaf blight, rust and leaf-spot classes. Leaves are uniformly green and firm, with a normal, well-developed canopy, tassel and ear, and no pustules, spots or blighting.', NULL, NULL, 'If no lesions, pustules or spots are visible, continue routine crop care - weekly field scouting, balanced nutrition and irrigation - and take a clear close-up photo of any leaf whose appearance changes so it can be matched against the disease cards.'),

('potato_early_blight', 'potato', 'Early Blight (target-spot disease of potato)', 'Alternaria solani', 'Early blight is a fungal disease of potato leaves, stems and tubers caused by Alternaria solani. It is widespread in both hills and plains of India and mainly attacks older, stressed or weak plants. It can cause substantial yield loss but is generally less devastating than late blight.', 'A fungus (Alternaria solani) that survives between crops in infected plant debris, soil, tubers and volunteer plants. It produces airborne spores spread by wind, wind-blown soil and splashing rain, and infection is favoured by warm, damp conditions and weak/stressed plants.', 'moderate - widespread annual disease in India''s warmer plains that can cut yields substantially, but generally far less destructive and slower than late blight', 'At the first appearance of dark spots with concentric rings, spray a protectant fungicide such as mancozeb or chlorothalonil (TNAU recommends about 2 g/L at 45, 60 and 75 days after planting), and remove/destroy heavily infected crop debris afterwards; for a region-specific schedule contact your local KVK or agriculture department.'),

('potato_late_blight', 'potato', 'Late Blight (potato blight)', 'Phytophthora infestans', 'Late blight, caused by the water-mould Phytophthora infestans, is the most devastating potato disease worldwide and historically caused the Irish potato famine. It is a recurrent and severe threat in India, cutting global potato production by around 15%, and under cool, wet weather it can destroy leaves, stems and tubers within days if uncontrolled.', 'A fungus-like water mould (oomycete), not a true fungus, producing airborne sporangia spread by wind and rain. It survives between seasons mainly in infected seed tubers, cull piles and volunteer potatoes, and under cool humid weather one infection cycle completes in 4-6 days, producing explosive epidemics.', 'potentially severe - the most destructive potato disease worldwide and a recurring major threat in the Indian plains and southern hills, capable of killing whole fields and rotting tubers within days under cool wet weather', 'On symptom-free plants, immediately apply a preventive mancozeb-chlorothalonil spray at 0.2% as advised by ICAR-CPRI; if dark water-soaked spots or white mould are already visible, spray cymoxanil+mancozeb or fenamidone+mancozeb or dimethomorph+mancozeb, repeat after about 10 days, alternate products, and contact the nearest KVK/agriculture department - late blight is a community emergency.'),

('potato_healthy', 'potato', 'Healthy Potato (No Disease)', NULL, 'A healthy potato plant grows uniformly with vigorous, green foliage and produces clean tubers free of rots, spots or mould. Keeping potatoes healthy is achieved mainly by planting certified disease-free seed and following basic field hygiene, rotation and balanced agronomy.', NULL, NULL, 'Plant certified disease-free seed potatoes in a well-drained, rotated field and follow good agronomy (balanced nutrition, controlled irrigation, weeding); inspect the crop at least weekly, rogue out any diseased plants immediately, and keep fields free of debris and volunteer potatoes to stay healthy.'),

('tomato_bacterial_spot', 'tomato', 'Bacterial Spot (bacterial leaf spot / black spot of tomato)', 'Xanthomonas species complex', 'A bacterial disease of tomato leaves, stems and fruit caused by a group (complex) of four Xanthomonas species, not a single bacterium. It spreads fast in warm, wet weather by rain splash and via contaminated seed, seedlings and solanaceous weeds. Infected fruit get scabby, brown spots and become unmarketable.', 'Microscopic bacteria are splashed from infected seed, seedlings, crop debris or solanaceous weeds onto leaves by rain, dew or sprinkler irrigation; they enter through natural openings/wounds and multiply inside leaves in warm, humid weather.', 'high - progresses rapidly in warm, wet weather, causing defoliation and scabby unmarketable fruit; copper-resistant Xanthomonas strains in several regions reduce chemical control options', 'Buy certified/pathogen-free seed and disease-free transplants and treat seed before sowing (hot water 50 C for 25 minutes); if spots appear, spray a copper-based bactericide (e.g., copper oxychloride) tank-mixed with mancozeb at the first sign and rogue badly infected plants.'),

('tomato_early_blight', 'tomato', 'Early Blight (target-spot / bull''s-eye leaf spot of tomato)', 'Alternaria solani', 'A very common fungal disease of tomato leaves, stems and fruit. Leaf lesions have dark concentric rings with a yellow margin and usually start on older, lower leaves. Warm, humid, rainy weather favours epidemics that can strip the plant of foliage.', 'The fungus survives between seasons in infected plant debris and in/on seed, and spores (conidia) are blown and splashed by wind and rain onto leaves. It infects most readily when nights/weather are warm, humid and rainy.', 'high - among the most common tomato diseases in India; repeated warm, humid, rainy spells cause heavy defoliation and fruit loss if left unmanaged', 'Remove and destroy infected crop debris, rotate away from solanaceous crops, and start protective fungicide sprays (TNAU options such as mancozeb 35% SC @ 1 kg/ac or iprodione 600 g/ac) as soon as bull''s-eye spots appear on lower leaves in warm humid weather.'),

('tomato_late_blight', 'tomato', 'Late Blight (tomato)', 'Phytophthora infestans', 'A devastating, fast-spreading disease of tomato and potato caused by the water mould Phytophthora infestans. It thrives in cool, humid weather and can destroy an entire field in a few days if conditions stay favourable.', 'A water mould that needs free moisture and cool humid air: spores blow long distances on the wind from other infected potato/tomato plants, transplants or debris and infect within hours on wet leaves.', 'potentially severe - can rot leaves, stems and fruit and destroy the whole crop within days under cool, wet weather; prevention before symptoms is essential because it cannot be cured once visible', 'Grow the resistant hybrid Arka Abhed F1 and, in high-rainfall areas, spray copper oxychloride 2.5 g/L preventively (ICAR-IIHR); if spots appear, pull out and bag infected plants immediately and spray a listed fungicide.'),

('tomato_leaf_mold', 'tomato', 'Tomato Leaf Mold (Cladosporium leaf mold)', 'Passalora fulva', 'A fungal disease mostly of greenhouse and high-tunnel tomatoes, driven by high humidity (above about 85%). Pale to yellow spots appear on the upper leaf surface with a velvety olive-brown mold growth on the undersides. Severe outbreaks defoliate plants and cut yield.', 'The fungus enters leaves through the stomata and grows inside the leaf, clogging tissues. It produces enormous numbers of spores on the lower leaf surface that spread on air currents within the humid canopy.', 'moderate - mostly a greenhouse/high-tunnel problem; severe humid outbreaks defoliate plants and lower yield, but fruit is not directly infected and plants are rarely killed outright', 'Cut humidity below 85% (ventilate/heat the structure, space and strip-prune plants for airflow) and use a leaf-mold-resistant variety; remove diseased leaves immediately when the olive fuzzy mold appears on leaf undersides.'),

('tomato_septoria_leaf_spot', 'tomato', 'Tomato Septoria Leaf Spot', 'Septoria lycopersici', 'A fungal disease of tomato foliage that is one of the most destructive leaf diseases of tomato worldwide. Small round spots with grey centres and dark margins appear first on lower leaves and the disease moves upward.', 'The fungus survives winter in infected tomato debris and on solanaceous weeds; spores ooze from small black fruiting bodies and are spread upward from plant to plant by rain splash and overhead watering.', 'high - rated among the most destructive foliage diseases of tomato; under warm wet weather it defoliates plants so severely that fruit sunscalds and yields fall', 'Strip and destroy infected lower leaves and crop debris, rotate for about 3 years, avoid overhead/night watering, and at first symptoms spray a protective fungicide (TNAU: fluxapyroxad + pyraclostrobin 200-250 ml/ha).'),

('tomato_spider_mites', 'tomato', 'Red Spider Mite / Two-Spotted Spider Mite (sap-sucking mites of tomato)', 'Tetranychus urticae', 'Tiny sap-sucking mites that live on the underside of tomato leaves, mostly in hot, dry or dusty conditions and under cover. Feeding removes sap and chlorophyll, causing leaves to turn reddish-brown and bronzy.', 'Spider mites feed on the lower leaf surface, piercing plant cells with stylets and sucking out cell contents; removal of chlorophyll causes the pale speckling and bronzing. Hot, dry, dusty conditions and water stress let populations explode.', 'potentially severe - under hot, dry conditions populations build up rapidly; severe infestation dries the foliage, webbing covers leaves, and flower/fruit formation is affected', 'Scout leaf undersides now; at first bronzing/stippling, spray with wettable sulphur 50 WP @ 2 g/L (TNAU), making sure the underside of leaves is covered, and keep the crop well watered to reduce heat-and-dust flare-ups.'),

('tomato_target_spot', 'tomato', 'Tomato Target Spot (target leaf spot)', 'Corynespora cassiicola', 'A fungal leaf, stem and fruit disease of tomato caused by Corynespora cassiicola, a fungus with a very wide host range. It is most serious in tropical/subtropical humid tomato areas and in greenhouses. Lesions resemble early blight because they develop concentric target-like rings.', 'A necrotrophic fungus with an enormous host range survives in crop residue and on many alternate hosts and weeds. Spores spread by splashing water, and infection needs warmth plus long leaf-wetness.', 'potentially severe - a leading destructive foliar/fruit disease of tomato in warm tropical-subtropical areas with no resistant commercial varieties and strobilurin-resistant strains documented', 'Reduce leaf wetness (wider spacing, prune lower leaves and suckers, stop overhead irrigation), rotate away from tomato for about 3 years, and begin protective sprays (mancozeb, chlorothalonil or copper oxychloride) before symptoms appear in warm humid weather.'),

('tomato_yellow_leaf_curl_virus', 'tomato', 'Tomato Leaf Curl / Tomato Yellow Leaf Curl (leaf curl of tomato)', 'Tomato yellow leaf curl virus (TYLCV)', 'A whitefly-transmitted viral disease that is among the most damaging tomato diseases in India, causing yield loss up to 70-100%. Infected plants show upward curling and cupping of top leaves, stunting and reduced fruit set; there is no cure once infected.', 'The begomovirus is carried and spread only by the whitefly Bemisia tabaci; a single whitefly can acquire and transmit the virus, and one viruliferous whitefly feeding can infect a plant.', 'potentially severe - the single most damaging tomato virus in India; IIHR reports 70-100% yield loss by stage of attack; no chemical cure exists', 'Scout the crop for curling/upward-cupping top leaves and check leaf undersides for whitefly. Rogue out and burn any curling plants, then strengthen vector control - keep nurseries under insect-proof net, use silver reflective mulch, and neonicotinoid sprays; next season plant a ToLCV-tolerant variety such as Arka Rakshak/Samrat.'),

('tomato_mosaic_virus', 'tomato', 'Tomato Mosaic (mottle of leaves and fruit)', 'Tomato mosaic virus (ToMV)', 'A very stable, easily-spread contact virus that mottles tomato leaves, distorts young growth and causes uneven ripening and brown patchiness on fruit. It rarely kills the plant but lowers yield and fruit quality.', 'ToMV spreads mechanically: on workers'' hands and clothes, contaminated tools, stakes and trellis twines, and via seed and infected plant debris; tobacco/cigarette products can carry TMV onto the crop.', 'moderate - rarely kills plants but lowers fruit number, size and quality; Indian tomato studies estimate about 18% yield loss; the virus is extremely stable and spreads easily by contact', 'Rogue out and burn any mottled, distorted, stunted plants immediately (do not compost them); wash hands with soap or dip them in milk and disinfect tools before touching healthy plants; do not smoke near the crop; next season use certified seed or treat seed with 10% trisodium phosphate / dry heat, and choose a Tm-resistant variety.'),

('tomato_healthy', 'tomato', 'Healthy Tomato Plant (no disease)', NULL, 'A tomato plant showing normal, vigorous growth with no mottling, curling, bronzing, webbing or wilt. Healthy plants have uniform dark-green foliage, steady flowering and normal fruit set, and respond to routine care.', NULL, NULL, 'Keep up the routine care - scout the field at least once a week, look under leaves with a hand lens, irrigate regularly (drip preferred), apply balanced fertilizer on schedule, and rogue out the first plant that shows curling, mottling or bronzing so the rest of the crop stays healthy.');

-- ====================================================================
-- Normalized Child Table Records for All 21 Diseases
-- ====================================================================

-- 1. Apple Scab
INSERT INTO disease_symptoms (disease_id, symptom_text) VALUES 
('apple_scab', 'Olive-green to dark-brown velvety spots on the underside of leaves and on the fruit surface'),
('apple_scab', 'Scabbed, cracked and misshapen fruit that rots easily in field or cold storage'),
('apple_scab', 'Premature yellowing of leaves and early leaf fall (defoliation)'),
('apple_scab', 'Poor fruit set and fruit drop in heavy infections');
INSERT INTO favorable_conditions (disease_id, condition_text) VALUES 
('apple_scab', 'Cool, wet spring weather with prolonged leaf wetness'),
('apple_scab', 'High humidity and rainfall from bud break (green tip) through fruit set'),
('apple_scab', 'Fallen infected leaves and fruit left lying in the orchard over winter');
INSERT INTO treatments (disease_id, category, treatment_text) VALUES 
('apple_scab', 'cultural', 'Rake up, remove and burn/compost fallen leaves and infected fruit in autumn'),
('apple_scab', 'cultural', 'Spray 5% urea on fallen leaves on the orchard floor to speed up leaf decomposition'),
('apple_scab', 'chemical', 'NHB/ICAR schedule per 100 L water: Mancozeb 400 g or Captan 300 g at silver-tip to green-tip stage');
INSERT INTO prevention_steps (disease_id, prevention_text) VALUES 
('apple_scab', 'Plant scab-resistant cultivars where available'),
('apple_scab', 'Remove or shred fallen leaves and infected fruit each autumn to cut primary inoculum');
INSERT INTO sources (disease_id, title, organization, url) VALUES 
('apple_scab', 'Apple - Diseases (Apple Scab control schedule)', 'National Horticulture Board (NHB)', 'https://nhb.gov.in/pdf/fruits/apple/app002.pdf'),
('apple_scab', 'Post Harvest Diseases :: Fruits :: Apple (Apple scab)', 'TNAU Agritech Portal', 'https://agritech.tnau.ac.in/crop_protection/crop_diseases_postharvest_apple_4.html');

-- 2. Apple Black Rot
INSERT INTO disease_symptoms (disease_id, symptom_text) VALUES 
('apple_black_rot', 'Small purple leaf specks that enlarge into tan-centred spots with darker rings (frogeye leaf spot)'),
('apple_black_rot', 'Firm brown-to-black fruit rot usually starting at the calyx end, often with concentric rings'),
('apple_black_rot', 'Fruit shrivels into black mummies that stay on the tree'),
('apple_black_rot', 'Sunken reddish-brown cankers on limbs and trunk');
INSERT INTO favorable_conditions (disease_id, condition_text) VALUES 
('apple_black_rot', 'Warm wet weather (leaf infection favours about 26-27 C with roughly 4 hours of wetting)'),
('apple_black_rot', 'Tree stress from drought, waterlogged soil, winter injury or fire blight damage');
INSERT INTO treatments (disease_id, category, treatment_text) VALUES 
('apple_black_rot', 'cultural', 'Remove and burn/bury all mummified fruit and dead, dying or cankered branches'),
('apple_black_rot', 'chemical', 'Carbendazim 25% + Flusilazole 12.5% SC at 160 ml per 200 L water (HP eUdyan)');
INSERT INTO prevention_steps (disease_id, prevention_text) VALUES 
('apple_black_rot', 'Sanitation is main control: remove mummies, dead wood, cankers'),
('apple_black_rot', 'Plant hardy cultivars in well-drained sites');
INSERT INTO sources (disease_id, title, organization, url) VALUES 
('apple_black_rot', 'Black rot of apple', 'University of Minnesota Extension', 'https://extension.umn.edu/yard-and-garden-problems/black-rot-apple');

-- 3. Apple Cedar-Apple Rust
INSERT INTO disease_symptoms (disease_id, symptom_text) VALUES 
('apple_cedar_apple_rust', 'Bright yellow-orange round spots on upper leaf surface with a red ring'),
('apple_cedar_apple_rust', 'Brownish tubular fungal structures on underside of leaf'),
('apple_cedar_apple_rust', 'Orange, slightly raised lesions on young fruit');
INSERT INTO favorable_conditions (disease_id, condition_text) VALUES 
('apple_cedar_apple_rust', 'Cedar or juniper trees within roughly a mile of apple trees'),
('apple_cedar_apple_rust', 'Warm, rainy spring weather');
INSERT INTO treatments (disease_id, category, treatment_text) VALUES 
('apple_cedar_apple_rust', 'cultural', 'Remove cedar/juniper trees near orchard or prune woody galls in winter');
INSERT INTO prevention_steps (disease_id, prevention_text) VALUES 
('apple_cedar_apple_rust', 'Keep apples and cedars/junipers separated');
INSERT INTO sources (disease_id, title, organization, url) VALUES 
('apple_cedar_apple_rust', 'Fact Sheet: Cedar Apple Rust', 'Cornell University', 'https://blogs.cornell.edu/applevarietydatabase/factsheet-cedar-apple-rust');

-- 4. Apple Healthy
INSERT INTO healthy_signs (disease_id, sign_text) VALUES 
('apple_healthy', 'Clean, uniform deep-green leaves without scab, rust, mildew or leaf spots'),
('apple_healthy', 'Well-formed fruits with smooth, clean skin and normal colour at maturity'),
('apple_healthy', 'No sunken cankers, oozing, dead twigs, root galls or white woolly aphid patches');
INSERT INTO prevention_steps (disease_id, prevention_text) VALUES 
('apple_healthy', 'Scout trees regularly from bud break for pests and diseases'),
('apple_healthy', 'Keep orchard floor clean; remove fallen leaves and mummies promptly');
INSERT INTO sources (disease_id, title, organization, url) VALUES 
('apple_healthy', 'Horticulture :: Fruits :: Apple', 'TNAU Agritech Portal', 'http://agritech.tnau.ac.in/horticulture/horti_fruits_apple.html');

-- 5. Corn Gray Leaf Spot
INSERT INTO disease_symptoms (disease_id, symptom_text) VALUES 
('corn_gray_leaf_spot', 'Narrow, rectangular, light-brown-to-grey necrotic lesions running parallel to leaf veins'),
('corn_gray_leaf_spot', 'Lesions join to form large blighted, silvery-grey areas covering whole leaves');
INSERT INTO favorable_conditions (disease_id, condition_text) VALUES 
('corn_gray_leaf_spot', 'Prolonged hot, humid weather with heavy dews and fog'),
('corn_gray_leaf_spot', 'Maize-after-maize cropping and reduced-till fields with surface residue');
INSERT INTO treatments (disease_id, category, treatment_text) VALUES 
('corn_gray_leaf_spot', 'cultural', 'Plant resistant or tolerant hybrids; rotate maize with non-host crops and bury residue');
INSERT INTO prevention_steps (disease_id, prevention_text) VALUES 
('corn_gray_leaf_spot', 'Use resistant maize hybrids and practice crop rotation');
INSERT INTO sources (disease_id, title, organization, url) VALUES 
('corn_gray_leaf_spot', 'Gray Leaf Spot (BP-56-W)', 'Purdue University Extension', 'https://www.extension.purdue.edu/extmedia/bp/BP-56-W.pdf');

-- 6. Corn Common Rust
INSERT INTO disease_symptoms (disease_id, symptom_text) VALUES 
('corn_common_rust', 'Minute pale flecks on both leaf surfaces enlarging into cinnamon-brown powdery pustules'),
('corn_common_rust', 'Pustules turn brownish-black as crop matures');
INSERT INTO favorable_conditions (disease_id, condition_text) VALUES 
('corn_common_rust', 'Cool, warm and moist weather - about 15-25 C'),
('corn_common_rust', 'Presence of Oxalis spp. alternate host weeds');
INSERT INTO treatments (disease_id, category, treatment_text) VALUES 
('corn_common_rust', 'cultural', 'Remove and destroy Oxalis weeds and crop remains'),
('corn_common_rust', 'chemical', 'Spray kresoxim-methyl 44.3% SC @ 1 ml/L or tebuconazole @ 1 ml/L at 35 and 50 DAS');
INSERT INTO prevention_steps (disease_id, prevention_text) VALUES 
('corn_common_rust', 'Plant rust-tolerant or resistant hybrids');
INSERT INTO sources (disease_id, title, organization, url) VALUES 
('corn_common_rust', 'Common Rust: Puccinia sorghi - Maize Diseases', 'TNAU Agritech Portal', 'https://agritech.tnau.ac.in/crop_protection/maize_disease_new/maize_4.html');

-- 7. Corn Northern Leaf Blight
INSERT INTO disease_symptoms (disease_id, symptom_text) VALUES 
('corn_northern_leaf_blight', 'Long, cigar-shaped grey-green to tan lesions tapering at both ends'),
('corn_northern_leaf_blight', 'Dusty, sooty black/green fungal spore fuzz on undersides of lesions');
INSERT INTO favorable_conditions (disease_id, condition_text) VALUES 
('corn_northern_leaf_blight', 'Wet, humid and cool weather later in the growing season'),
('corn_northern_leaf_blight', 'Continuous maize cropping with infected stubble left in field');
INSERT INTO treatments (disease_id, category, treatment_text) VALUES 
('corn_northern_leaf_blight', 'cultural', 'Burn or bury infected maize stubbles after harvest'),
('corn_northern_leaf_blight', 'chemical', 'Spray mancozeb or zineb @ 2-4 g/L or propiconazole 25% EC @ 1 ml/L at 35 and 50 DAS');
INSERT INTO prevention_steps (disease_id, prevention_text) VALUES 
('corn_northern_leaf_blight', 'Plant resistant/partially resistant hybrids');
INSERT INTO sources (disease_id, title, organization, url) VALUES 
('corn_northern_leaf_blight', 'Leaf Blight: Exserohilum turcicum', 'TNAU Agritech Portal', 'https://agritech.tnau.ac.in/crop_protection/maize_disease_new/maize_2.html');

-- 8. Corn Healthy
INSERT INTO healthy_signs (disease_id, sign_text) VALUES 
('corn_healthy', 'Uniformly green leaves with no long cigar-shaped blight lesions or rust pustules'),
('corn_healthy', 'Leaves remain green and firm - not greyish, dry or burnt looking'),
('corn_healthy', 'Normal plant height and growth habit with healthy tassel and developing ear');
INSERT INTO prevention_steps (disease_id, prevention_text) VALUES 
('corn_healthy', 'Scout fields regularly and spot-check leaves'),
('corn_healthy', 'Use recommended varieties, balanced fertilizer and ICAR crop advisories');
INSERT INTO sources (disease_id, title, organization, url) VALUES 
('corn_healthy', 'Maize Diseases and their Management', 'ICAR-IIMR', 'https://www.iimr.res.in/storage/publications/bulletins/maize-diseases-and-their-management.pdf');

-- 9. Potato Early Blight
INSERT INTO disease_symptoms (disease_id, symptom_text) VALUES 
('potato_early_blight', 'Brown-black angular-to-oval necrotic spots with dark concentric rings (target pattern)'),
('potato_early_blight', 'Lesions first appear on oldest lower leaves and progress upward');
INSERT INTO favorable_conditions (disease_id, condition_text) VALUES 
('potato_early_blight', 'Warm weather near 20-30 C with high humidity and repeated leaf wetness'),
('potato_early_blight', 'Older, stressed or poorly nourished plants');
INSERT INTO treatments (disease_id, category, treatment_text) VALUES 
('potato_early_blight', 'cultural', 'Remove and destroy infected crop debris after harvest and practice crop rotation'),
('potato_early_blight', 'chemical', 'Mancozeb 2 g/L or Chlorothalonil 2 g/L sprayed at 45, 60, and 75 days after planting');
INSERT INTO prevention_steps (disease_id, prevention_text) VALUES 
('potato_early_blight', 'Use certified disease-free seed potatoes'),
('potato_early_blight', 'Keep plants healthy with balanced nutrition and proper irrigation');
INSERT INTO sources (disease_id, title, organization, url) VALUES 
('potato_early_blight', 'Horticultural crops :: Vegetables :: Potato - Early blight', 'TNAU Agritech Portal', 'https://agritech.tnau.ac.in/crop_protection/crop_prot_crop%20diseases_veg_potato_2.html');

-- 10. Potato Late Blight
INSERT INTO disease_symptoms (disease_id, symptom_text) VALUES 
('potato_late_blight', 'Light-to-dark green water-soaked spots enlarging rapidly into blackish/brown necrotic areas'),
('potato_late_blight', 'White fungal/mould growth on undersides of leaves in moist weather'),
('potato_late_blight', 'Tubers develop purplish-brown sunken spots with rusty-brown necrosis inside');
INSERT INTO favorable_conditions (disease_id, condition_text) VALUES 
('potato_late_blight', 'Cool, moist weather roughly 10-25 C with night temperatures around 10 C'),
('potato_late_blight', 'Relative humidity above 90% and rainfall followed by cloudy days');
INSERT INTO treatments (disease_id, category, treatment_text) VALUES 
('potato_late_blight', 'cultural', 'Plant certified seed tubers; destroy cull piles and volunteer potatoes'),
('potato_late_blight', 'chemical', 'Preventive mancozeb-chlorothalonil 0.2%; curative cymoxanil+mancozeb or fenamidone+mancozeb');
INSERT INTO prevention_steps (disease_id, prevention_text) VALUES 
('potato_late_blight', 'Plant certified disease-free seed potatoes from CPRI-approved sources'),
('potato_late_blight', 'Follow CPRI advisories and INDOBLIGHTCAST forecast');
INSERT INTO sources (disease_id, title, organization, url) VALUES 
('potato_late_blight', 'Potato - Late blight of potato', 'TNAU Agritech Portal', 'https://agritech.tnau.ac.in/crop_protection/crop_prot_crop%20diseases_veg_potato_1.html');

-- 11. Potato Healthy
INSERT INTO healthy_signs (disease_id, sign_text) VALUES 
('potato_healthy', 'Uniformly green, vigorous foliage without leaf spots or concentric-ring lesions'),
('potato_healthy', 'Stems firm and upright, no dark/brown lesions or node breakage'),
('potato_healthy', 'Tubers smooth-skinned, with no water-soaked or purplish-brown sunken patches');
INSERT INTO prevention_steps (disease_id, prevention_text) VALUES 
('potato_healthy', 'Plant certified disease-free seed potatoes (seed-plot technique)'),
('potato_healthy', 'Practice crop rotation with non-solanaceous crops');
INSERT INTO sources (disease_id, title, organization, url) VALUES 
('potato_healthy', 'Hi-tech seed production system revolutionizing seed potato industry', 'ICAR-CPRI', 'https://icar.org.in/en/node/3854');

-- 12. Tomato Bacterial Spot
INSERT INTO disease_symptoms (disease_id, symptom_text) VALUES 
('tomato_bacterial_spot', 'Small water-soaked brown or black spots on leaves with yellow halos'),
('tomato_bacterial_spot', 'Blister-like water-soaked spots on green fruit turning brown, sunken and scabby');
INSERT INTO favorable_conditions (disease_id, condition_text) VALUES 
('tomato_bacterial_spot', 'Warm temperatures about 24-30 C with high relative humidity and splattering rain');
INSERT INTO treatments (disease_id, category, treatment_text) VALUES 
('tomato_bacterial_spot', 'cultural', 'Use certified/pathogen-free seed and disease-free transplants; hot-water seed treatment'),
('tomato_bacterial_spot', 'chemical', 'Streptocycline 40-100 ppm (20 g/ac) or copper-based bactericides tank-mixed with mancozeb');
INSERT INTO prevention_steps (disease_id, prevention_text) VALUES 
('tomato_bacterial_spot', 'Use certified, pathogen-free seed and disease-free seedlings'),
('tomato_bacterial_spot', 'Implement 3-year crop rotation and remove solanaceous weeds');
INSERT INTO sources (disease_id, title, organization, url) VALUES 
('tomato_bacterial_spot', 'Tomato - Bacterial leaf spot', 'TNAU Agritech Portal', 'https://agritech.tnau.ac.in/crop_protection/tomato_diseases_11.html');

-- 13. Tomato Early Blight
INSERT INTO disease_symptoms (disease_id, symptom_text) VALUES 
('tomato_early_blight', 'Brown spots with concentric rings in bull''s-eye pattern with yellow margin on leaves'),
('tomato_early_blight', 'Fruit infection through calyx with brown concentric-ring lesions');
INSERT INTO favorable_conditions (disease_id, condition_text) VALUES 
('tomato_early_blight', 'Warm, humid (24-29 C), rainy and wet weather with leaf moisture');
INSERT INTO treatments (disease_id, category, treatment_text) VALUES 
('tomato_early_blight', 'cultural', 'Removal and destruction of crop debris; 2-3 year crop rotation'),
('tomato_early_blight', 'chemical', 'Mancozeb 35% SC @ 1 kg/ac or iprodione 50% WP @ 600 g/ac');
INSERT INTO prevention_steps (disease_id, prevention_text) VALUES 
('tomato_early_blight', 'Use disease-free certified seed and healthy transplants'),
('tomato_early_blight', 'Stake plants and use drip irrigation to keep leaves dry');
INSERT INTO sources (disease_id, title, organization, url) VALUES 
('tomato_early_blight', 'Tomato - Early Blight', 'TNAU Agritech Portal', 'https://agritech.tnau.ac.in/crop_protection/tomato_diseases_2.html');

-- 14. Tomato Late Blight
INSERT INTO disease_symptoms (disease_id, symptom_text) VALUES 
('tomato_late_blight', 'Water-soaked black lesions on leaves expanding rapidly until whole leaf is necrotic'),
('tomato_late_blight', 'Rings of greyish-white fuzzy sporulation on undersides of leaves');
INSERT INTO favorable_conditions (disease_id, condition_text) VALUES 
('tomato_late_blight', 'Cool, humid weather around 15-18 C with high humidity near 90%');
INSERT INTO treatments (disease_id, category, treatment_text) VALUES 
('tomato_late_blight', 'cultural', 'Grow resistant hybrid Arka Abhed F1; proper drainage and field hygiene'),
('tomato_late_blight', 'chemical', 'Preventive copper oxychloride 2.5 g/L or cyazofamid 34.5% SC @ 80 ml/ac');
INSERT INTO prevention_steps (disease_id, prevention_text) VALUES 
('tomato_late_blight', 'Use resistant varieties/hybrids such as Arka Abhed F1'),
('tomato_late_blight', 'Avoid overhead sprinkler irrigation that keeps foliage wet');
INSERT INTO sources (disease_id, title, organization, url) VALUES 
('tomato_late_blight', 'Late blight disease of tomato', 'ICAR Indian Horticulture', 'https://epubs.icar.org.in/index.php/IndHort/article/view/164935');

-- 15. Tomato Leaf Mold
INSERT INTO disease_symptoms (disease_id, symptom_text) VALUES 
('tomato_leaf_mold', 'White or pale green-yellow spots on upper surfaces of older leaves'),
('tomato_leaf_mold', 'Velvety, olive-brown fungal growth on undersides of leaves');
INSERT INTO favorable_conditions (disease_id, condition_text) VALUES 
('tomato_leaf_mold', 'Relative humidity above 85% with temperatures about 20-24 C');
INSERT INTO treatments (disease_id, category, treatment_text) VALUES 
('tomato_leaf_mold', 'cultural', 'Keep relative humidity below 85% by ventilating and heating structures');
INSERT INTO prevention_steps (disease_id, prevention_text) VALUES 
('tomato_leaf_mold', 'Select resistant cultivars with Cf resistance genes'),
('tomato_leaf_mold', 'Manage humidity and prune canopy for air circulation');
INSERT INTO sources (disease_id, title, organization, url) VALUES 
('tomato_leaf_mold', 'Tomato Leaf Mold', 'Cornell University', 'https://www.vegetables.cornell.edu/pest-management/disease-factsheets/tomato-leaf-mold');

-- 16. Tomato Septoria Leaf Spot
INSERT INTO disease_symptoms (disease_id, symptom_text) VALUES 
('tomato_septoria_leaf_spot', 'Small circular to irregular spots with grey/tan centres and dark brown margins'),
('tomato_septoria_leaf_spot', 'Tiny black pinhead fruiting bodies visible in pale centres');
INSERT INTO favorable_conditions (disease_id, condition_text) VALUES 
('tomato_septoria_leaf_spot', 'High humidity, warm wet weather with splashing rain and overhead watering');
INSERT INTO treatments (disease_id, category, treatment_text) VALUES 
('tomato_septoria_leaf_spot', 'cultural', 'Removal and destruction of affected plant parts; 3-4 year crop rotation'),
('tomato_septoria_leaf_spot', 'chemical', 'Fluxapyroxad 250 g/L + Pyraclostrobin 250 g/L SC @ 200-250 ml/ha');
INSERT INTO prevention_steps (disease_id, prevention_text) VALUES 
('tomato_septoria_leaf_spot', 'Remove and destroy infected lower leaves and all crop debris'),
('tomato_septoria_leaf_spot', 'Avoid overhead watering and space plants for good airflow');
INSERT INTO sources (disease_id, title, organization, url) VALUES 
('tomato_septoria_leaf_spot', 'Tomato - Septoria Leaf Spot', 'TNAU Agritech Portal', 'https://agritech.tnau.ac.in/crop_protection/tomato_diseases_4.html');

-- 17. Tomato Spider Mites
INSERT INTO disease_symptoms (disease_id, symptom_text) VALUES 
('tomato_spider_mites', 'Tiny pale-yellow stippling / shiny speckling on upper leaf surface'),
('tomato_spider_mites', 'Leaves turn reddish-brown, bronzy, and wither in severe infestation');
INSERT INTO favorable_conditions (disease_id, condition_text) VALUES 
('tomato_spider_mites', 'Hot, dry weather and dusty field/roadside conditions; water-stressed plants');
INSERT INTO treatments (disease_id, category, treatment_text) VALUES 
('tomato_spider_mites', 'cultural', 'Water plants regularly to reduce dust and heat stress'),
('tomato_spider_mites', 'chemical', 'Wettable sulphur 50 WP @ 2 g/L water spray (TNAU)');
INSERT INTO prevention_steps (disease_id, prevention_text) VALUES 
('tomato_spider_mites', 'Regular field scouting using a hand lens on leaf undersides'),
('tomato_spider_mites', 'Maintain adequate irrigation to avoid dry, dusty plants');
INSERT INTO sources (disease_id, title, organization, url) VALUES 
('tomato_spider_mites', 'Red spider mite: Tetranychus spp.', 'TNAU Agritech Portal', 'https://agritech.tnau.ac.in/crop_protection/tomato/tomato_7.html');

-- 18. Tomato Target Spot
INSERT INTO disease_symptoms (disease_id, symptom_text) VALUES 
('tomato_target_spot', 'Small dark-brown pinpoint lesions expanding into round lesions with concentric target rings'),
('tomato_target_spot', 'Chlorotic halo around lesions with fruit spotting making fruit unmarketable');
INSERT INTO favorable_conditions (disease_id, condition_text) VALUES 
('tomato_target_spot', 'Warm temperatures about 20-28 C with long leaf-wetness periods and high humidity');
INSERT INTO treatments (disease_id, category, treatment_text) VALUES 
('tomato_target_spot', 'cultural', 'Improve airflow with wider spacing, prune suckers, avoid overhead irrigation');
INSERT INTO prevention_steps (disease_id, prevention_text) VALUES 
('tomato_target_spot', 'Preventative protectant fungicide applications (mancozeb/chlorothalonil)'),
('tomato_target_spot', 'Crop rotation of 3 or more years away from tomato');
INSERT INTO sources (disease_id, title, organization, url) VALUES 
('tomato_target_spot', 'Corynespora cassiicola datasheet', 'CABI Compendium', 'https://www.cabidigitallibrary.org/doi/full/10.1079/cabicompendium.15467');

-- 19. Tomato Yellow Leaf Curl Virus
INSERT INTO disease_symptoms (disease_id, symptom_text) VALUES 
('tomato_yellow_leaf_curl_virus', 'Upward curling, cupping and yellowing of young/top leaves'),
('tomato_yellow_leaf_curl_virus', 'Reduced leaflet size, severe stunting, and heavily reduced flowering/fruit set');
INSERT INTO favorable_conditions (disease_id, condition_text) VALUES 
('tomato_yellow_leaf_curl_virus', 'High whitefly (Bemisia tabaci) populations under warm, dry-but-humid conditions');
INSERT INTO treatments (disease_id, category, treatment_text) VALUES 
('tomato_yellow_leaf_curl_virus', 'cultural', 'Raise nursery under 40-50 mesh insect-proof net; grow tolerant varieties like Arka Rakshak'),
('tomato_yellow_leaf_curl_virus', 'chemical', 'Thiamethoxam 75 WG seed treatment @ 5 g/kg seed or imidacloprid root dip');
INSERT INTO prevention_steps (disease_id, prevention_text) VALUES 
('tomato_yellow_leaf_curl_virus', 'Use ToLCV-tolerant varieties/hybrids (IIHR Arka series)'),
('tomato_yellow_leaf_curl_virus', 'Raise seedlings under insect-proof nets');
INSERT INTO sources (disease_id, title, organization, url) VALUES 
('tomato_yellow_leaf_curl_virus', 'Arka Rakshak tomato hybrid', 'ICAR-IIHR', 'https://www.iihr.res.in/arka-rakshak-high-yielding-triple-disease-resistant-tomato-f1-hybrid-export-potential');

-- 20. Tomato Mosaic Virus
INSERT INTO disease_symptoms (disease_id, symptom_text) VALUES 
('tomato_mosaic_virus', 'Light-and-dark green blotchy mosaic or mottling on leaves'),
('tomato_mosaic_virus', 'Leaf distortion, fern-leaf appearance, and unevenly ripened fruit with brown patches');
INSERT INTO favorable_conditions (disease_id, condition_text) VALUES 
('tomato_mosaic_virus', 'Mechanical handling and contact transmission during crop management in fields or greenhouses');
INSERT INTO treatments (disease_id, category, treatment_text) VALUES 
('tomato_mosaic_virus', 'cultural', 'Extreme sanitation: wash hands with soap/milk, disinfect tools, remove infected plants');
INSERT INTO prevention_steps (disease_id, prevention_text) VALUES 
('tomato_mosaic_virus', 'Use certified disease-free seed treated with trisodium phosphate'),
('tomato_mosaic_virus', 'Plant ToMV-resistant varieties carrying Tm resistance genes');
INSERT INTO sources (disease_id, title, organization, url) VALUES 
('tomato_mosaic_virus', 'Tobamoviruses that affect tomato', 'NC State Extension', 'https://content.ces.ncsu.edu/tobamoviruses-that-affect-tomato-tmv-tomv-tobrfv');

-- 21. Tomato Healthy
INSERT INTO healthy_signs (disease_id, sign_text) VALUES 
('tomato_healthy', 'Uniform dark-green leaves with no mosaic/mottling, curling, yellowing or bronzing'),
('tomato_healthy', 'No silken webbing or mite speckling on leaf undersides; no whitefly colonies'),
('tomato_healthy', 'Upright, vigorous stem growth without stunting or wilting with normal fruit set');
INSERT INTO prevention_steps (disease_id, prevention_text) VALUES 
('tomato_healthy', 'Follow recommended package of practices (insect-proof nursery, proper spacing)'),
('tomato_healthy', 'Balanced fertilization and regular drip irrigation');
INSERT INTO sources (disease_id, title, organization, url) VALUES 
('tomato_healthy', 'Tomato - Cultivation Details', 'ICAR-IIVR Varanasi', 'https://icariivr.org.in/tomato-variety/');

-- ====================================================================
-- ML Class Mapping (MobileNet v3 class outputs -> disease_id)
-- ====================================================================
CREATE TABLE IF NOT EXISTS ml_class_mapping (
    id SERIAL PRIMARY KEY,
    ml_class_name VARCHAR(255) NOT NULL UNIQUE,
    disease_id VARCHAR(100) NOT NULL,
    FOREIGN KEY (disease_id) REFERENCES diseases(disease_id)
);

INSERT INTO ml_class_mapping (ml_class_name, disease_id) VALUES
('Apple___Apple_scab', 'apple_scab'),
('Apple___Black_rot', 'apple_black_rot'),
('Apple___Cedar_apple_rust', 'apple_cedar_apple_rust'),
('Apple___healthy', 'apple_healthy'),
('Corn_(maize)___Cercospora_leaf_spot Gray_leaf_spot', 'corn_gray_leaf_spot'),
('Corn_(maize)___Common_rust_', 'corn_common_rust'),
('Corn_(maize)___Northern_Leaf_Blight', 'corn_northern_leaf_blight'),
('Corn_(maize)___healthy', 'corn_healthy'),
('Potato___Early_blight', 'potato_early_blight'),
('Potato___Late_blight', 'potato_late_blight'),
('Potato___healthy', 'potato_healthy'),
('Tomato___Bacterial_spot', 'tomato_bacterial_spot'),
('Tomato___Early_blight', 'tomato_early_blight'),
('Tomato___Late_blight', 'tomato_late_blight'),
('Tomato___Leaf_Mold', 'tomato_leaf_mold'),
('Tomato___Septoria_leaf_spot', 'tomato_septoria_leaf_spot'),
('Tomato___Spider_mites Two-spotted_spider_mite', 'tomato_spider_mites'),
('Tomato___Target_Spot', 'tomato_target_spot'),
('Tomato___Tomato_Yellow_Leaf_Curl_Virus', 'tomato_yellow_leaf_curl_virus'),
('Tomato___Tomato_mosaic_virus', 'tomato_mosaic_virus'),
('Tomato___healthy', 'tomato_healthy');