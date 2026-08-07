/**
 * Task copy for the scheduler, in every language the app ships.
 *
 * The scheduler writes finished strings into the task document because the
 * clients already in people's hands read `title`/`detail`/`kv`/`body` directly.
 * The newer client prefers to build the same text from its own ARB (so that
 * switching the interface language re-renders tasks that are already stored),
 * and falls back to these strings when it cannot.
 *
 * Keep the key set identical across locales — `taskStrings` falls back to
 * English per key, so a missing one degrades to English rather than crashing.
 */

const LOCALES = ['en', 'ru', 'uk', 'de', 'fr', 'es'];

const STRINGS = {
  en: {
    waterTitle: 'Water the plant',
    waterDetail: (ml) => `${ml} ml — until the saucer is damp`,
    waterDetailPlain: 'Water until the saucer is damp',
    waterBody:
      'Water on the plant\'s own schedule, going by how dry the top layer of ' +
      'soil is.|Pour away what collects in the saucer — standing water hurts ' +
      'the roots more than a missed watering.',
    fertTitle: 'Feed the plant',
    fertDetail: 'Balanced fertiliser, half strength',
    fertBody:
      'While the plant is growing, feed it every two weeks with a balanced ' +
      'fertiliser diluted to half the strength on the label.|Do not feed just ' +
      'after repotting or into dry soil — water it first.',
    scanTitle: 'Re-scan the plant',
    scanDetail: 'A fresh photo sharpens the health score',
    scanBody:
      'Regular checks show the trend: next to the older photos it is clear ' +
      'whether things are improving or not.|Shoot the whole plant, so the pot ' +
      'and the surface of the soil are visible.',
    kvVolume: 'Volume',
    kvThisIs: 'That is',
    kvCycle: 'Cycle',
    kvRhythm: 'Rhythm',
    kvDose: 'Dose',
    kvNeeds: 'Needs',
    valEveryNDays: (n) => `every ${n} d.`,
    valFortnightly: 'every 2 weeks',
    valMonthly: 'once a month',
    valHalfDose: '½ strength',
    valPhotos: '1–3 photos',
    unitMl: 'ml',
    unitGlasses: 'glasses',
  },
  ru: {
    waterTitle: 'Полить растение',
    waterDetail: (ml) => `${ml} мл — до появления влаги в поддоне`,
    waterDetailPlain: 'Полейте до появления влаги в поддоне',
    waterBody:
      'Поливайте по расписанию растения, ориентируясь на сухость верхнего ' +
      'слоя почвы.|Лишнюю воду из поддона сливайте — застой у корней вреднее ' +
      'недолива.',
    fertTitle: 'Подкормить растение',
    fertDetail: 'Комплексное удобрение, половина дозы',
    fertBody:
      'В период активного роста подкармливайте раз в две недели комплексным ' +
      'удобрением, разведённым вдвое слабее указанного на упаковке.|Не ' +
      'подкармливайте сразу после пересадки и по сухой земле — сначала полейте.',
    scanTitle: 'Пересканировать растение',
    scanDetail: 'Свежее фото уточнит оценку состояния',
    scanBody:
      'Регулярный анализ показывает динамику: по сравнению со старыми ' +
      'снимками видно, улучшается состояние или ухудшается.|Снимите растение ' +
      'целиком, чтобы был виден горшок и поверхность почвы.',
    kvVolume: 'Объём',
    kvThisIs: 'Это',
    kvCycle: 'Цикл',
    kvRhythm: 'Ритм',
    kvDose: 'Доза',
    kvNeeds: 'Нужно',
    valEveryNDays: (n) => `каждые ${n} дн.`,
    valFortnightly: 'раз в 2 недели',
    valMonthly: 'раз в месяц',
    valHalfDose: '½ нормы',
    valPhotos: '1–3 фото',
    unitMl: 'мл',
    unitGlasses: 'стакана',
  },
  uk: {
    waterTitle: 'Полити рослину',
    waterDetail: (ml) => `${ml} мл — до появи вологи в піддоні`,
    waterDetailPlain: 'Полийте до появи вологи в піддоні',
    waterBody:
      'Поливайте за розкладом рослини, орієнтуючись на сухість верхнього ' +
      'шару ґрунту.|Зайву воду з піддона зливайте — застій біля коренів ' +
      'шкідливіший за недолив.',
    fertTitle: 'Підживити рослину',
    fertDetail: 'Комплексне добриво, половина дози',
    fertBody:
      'У період активного росту підживлюйте раз на два тижні комплексним ' +
      'добривом, розведеним удвічі слабше за вказане на упаковці.|Не ' +
      'підживлюйте одразу після пересадки та по сухій землі — спершу полийте.',
    scanTitle: 'Пересканувати рослину',
    scanDetail: 'Свіже фото уточнить оцінку стану',
    scanBody:
      'Регулярний аналіз показує динаміку: порівняно зі старими знімками ' +
      'видно, покращується стан чи погіршується.|Зніміть рослину повністю, ' +
      'щоб було видно горщик і поверхню ґрунту.',
    kvVolume: 'Обʼєм',
    kvThisIs: 'Це',
    kvCycle: 'Цикл',
    kvRhythm: 'Ритм',
    kvDose: 'Доза',
    kvNeeds: 'Потрібно',
    valEveryNDays: (n) => `кожні ${n} дн.`,
    valFortnightly: 'раз на 2 тижні',
    valMonthly: 'раз на місяць',
    valHalfDose: '½ норми',
    valPhotos: '1–3 фото',
    unitMl: 'мл',
    unitGlasses: 'склянки',
  },
  de: {
    waterTitle: 'Pflanze gießen',
    waterDetail: (ml) => `${ml} ml — bis der Untersetzer feucht ist`,
    waterDetailPlain: 'Gießen, bis der Untersetzer feucht ist',
    waterBody:
      'Gießen Sie nach dem Rhythmus der Pflanze und achten Sie darauf, wie ' +
      'trocken die obere Erdschicht ist.|Überschüssiges Wasser aus dem ' +
      'Untersetzer abgießen — Staunässe schadet den Wurzeln mehr als zu ' +
      'seltenes Gießen.',
    fertTitle: 'Pflanze düngen',
    fertDetail: 'Volldünger, halbe Dosis',
    fertBody:
      'Während des Wachstums alle zwei Wochen mit einem Volldünger düngen, ' +
      'auf die halbe Konzentration verdünnt.|Nicht direkt nach dem Umtopfen ' +
      'und nicht auf trockene Erde düngen — vorher gießen.',
    scanTitle: 'Pflanze neu scannen',
    scanDetail: 'Ein frisches Foto schärft die Bewertung',
    scanBody:
      'Regelmäßige Analysen zeigen den Verlauf: im Vergleich mit älteren ' +
      'Aufnahmen sieht man, ob es besser oder schlechter wird.|Fotografieren ' +
      'Sie die ganze Pflanze, sodass Topf und Erdoberfläche sichtbar sind.',
    kvVolume: 'Menge',
    kvThisIs: 'Das sind',
    kvCycle: 'Zyklus',
    kvRhythm: 'Rhythmus',
    kvDose: 'Dosis',
    kvNeeds: 'Benötigt',
    valEveryNDays: (n) => `alle ${n} Tg.`,
    valFortnightly: 'alle 2 Wochen',
    valMonthly: 'einmal im Monat',
    valHalfDose: '½ Dosis',
    valPhotos: '1–3 Fotos',
    unitMl: 'ml',
    unitGlasses: 'Gläser',
  },
  fr: {
    waterTitle: 'Arroser la plante',
    waterDetail: (ml) => `${ml} ml — jusqu'à ce que la soucoupe soit humide`,
    waterDetailPlain: "Arrosez jusqu'à ce que la soucoupe soit humide",
    waterBody:
      'Arrosez au rythme de la plante, en vous fiant à la sécheresse de la ' +
      "couche supérieure du terreau.|Videz l'eau qui reste dans la soucoupe — " +
      "l'eau stagnante nuit plus aux racines qu'un arrosage manqué.",
    fertTitle: 'Fertiliser la plante',
    fertDetail: 'Engrais complet, demi-dose',
    fertBody:
      'En pleine croissance, fertilisez toutes les deux semaines avec un ' +
      "engrais complet dilué à moitié.|Ne fertilisez pas juste après un " +
      'rempotage ni sur terre sèche — arrosez d\'abord.',
    scanTitle: 'Scanner à nouveau la plante',
    scanDetail: "Une photo récente affine l'évaluation",
    scanBody:
      "Une analyse régulière montre l'évolution : comparée aux anciennes " +
      "photos, on voit si l'état s'améliore ou non.|Photographiez la plante " +
      'entière, pot et surface du terreau visibles.',
    kvVolume: 'Volume',
    kvThisIs: 'Soit',
    kvCycle: 'Cycle',
    kvRhythm: 'Rythme',
    kvDose: 'Dose',
    kvNeeds: 'Nécessite',
    valEveryNDays: (n) => `tous les ${n} j.`,
    valFortnightly: 'toutes les 2 semaines',
    valMonthly: 'une fois par mois',
    valHalfDose: '½ dose',
    valPhotos: '1–3 photos',
    unitMl: 'ml',
    unitGlasses: 'verres',
  },
  es: {
    waterTitle: 'Regar la planta',
    waterDetail: (ml) => `${ml} ml — hasta que el plato esté húmedo`,
    waterDetailPlain: 'Riega hasta que el plato esté húmedo',
    waterBody:
      'Riega según el ritmo de la planta, guiándote por lo seca que esté la ' +
      'capa superior del sustrato.|Vacía el agua que quede en el plato: el ' +
      'encharcamiento daña más las raíces que un riego omitido.',
    fertTitle: 'Abonar la planta',
    fertDetail: 'Fertilizante completo, media dosis',
    fertBody:
      'Durante el crecimiento, abona cada dos semanas con un fertilizante ' +
      'completo diluido a la mitad.|No abones justo después de trasplantar ni ' +
      'sobre tierra seca: riega primero.',
    scanTitle: 'Volver a escanear la planta',
    scanDetail: 'Una foto reciente afina la evaluación',
    scanBody:
      'El análisis regular muestra la evolución: comparado con las fotos ' +
      'antiguas se ve si mejora o empeora.|Fotografía la planta entera, con ' +
      'la maceta y la superficie del sustrato a la vista.',
    kvVolume: 'Volumen',
    kvThisIs: 'Equivale a',
    kvCycle: 'Ciclo',
    kvRhythm: 'Ritmo',
    kvDose: 'Dosis',
    kvNeeds: 'Necesita',
    valEveryNDays: (n) => `cada ${n} d.`,
    valFortnightly: 'cada 2 semanas',
    valMonthly: 'una vez al mes',
    valHalfDose: '½ dosis',
    valPhotos: '1–3 fotos',
    unitMl: 'ml',
    unitGlasses: 'vasos',
  },
};

/** Normalises anything the user document holds into a supported language code. */
function normaliseLocale(raw) {
  const code = String(raw || '')
    .trim()
    .toLowerCase()
    .split(/[-_]/)[0];
  return LOCALES.includes(code) ? code : 'en';
}

/** Strings for one locale, each key falling back to English when absent. */
function taskStrings(locale) {
  const code = normaliseLocale(locale);
  return new Proxy(STRINGS[code], {
    get: (target, key) =>
      key in target ? target[key] : STRINGS.en[key],
  });
}

module.exports = { LOCALES, normaliseLocale, taskStrings };
