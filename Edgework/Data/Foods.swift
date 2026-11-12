import Foundation

// Approximate values per listed serving, based on standard USDA reference data.

private func f(_ id: String, _ name: String, _ g: FoodGroup, _ serving: String,
               _ kcal: Double, _ p: Double, _ c: Double, _ fat: Double, fiber: Double = 0,
               _ benefits: [FoodBenefit] = [], _ note: String = "") -> Food {
    Food(id: id, name: name, group: g, serving: serving, kcal: kcal, protein: p, carbs: c, fat: fat, fiber: fiber, benefits: benefits, note: note)
}

enum FoodDB {
    static let all: [Food] = Array(([fruit, veg, grains, protein, dairy, fats, snacks, meals, drinks, sweets] as [[Food]]).joined())
    static let byID: [String: Food] = Dictionary(uniqueKeysWithValues: all.map { ($0.id, $0) })

    static let fruit: [Food] = [
        f("banana", "Banana", .fruit, "1 medium", 105, 1.3, 27, 0.4, fiber: 3.1, [.energy, .heart], "Fast carbs and potassium. Perfect 30–60 min before a game."),
        f("apple", "Apple", .fruit, "1 medium", 95, 0.5, 25, 0.3, fiber: 4.4, [.gut, .energy]),
        f("orange", "Orange", .fruit, "1 medium", 62, 1.2, 15, 0.2, fiber: 3.1, [.immunity, .hydration], "A full day of vitamin C."),
        f("strawberries", "Strawberries", .fruit, "1 cup", 49, 1, 12, 0.5, fiber: 3, [.immunity, .antiInflammatory]),
        f("blueberries", "Blueberries", .fruit, "1 cup", 84, 1.1, 21, 0.5, fiber: 3.6, [.antiInflammatory, .brain], "Antioxidants that may help with soreness."),
        f("raspberries", "Raspberries", .fruit, "1 cup", 64, 1.5, 15, 0.8, fiber: 8, [.gut, .antiInflammatory]),
        f("grapes", "Grapes", .fruit, "1 cup", 104, 1.1, 27, 0.2, fiber: 1.4, [.energy, .hydration]),
        f("watermelon", "Watermelon", .fruit, "2 cups", 92, 1.9, 23, 0.5, fiber: 1.2, [.hydration], "92% water. Great on hot days."),
        f("pineapple", "Pineapple", .fruit, "1 cup", 82, 0.9, 22, 0.2, fiber: 2.3, [.antiInflammatory, .immunity], "Contains bromelain, linked to reduced inflammation."),
        f("mango", "Mango", .fruit, "1 cup", 99, 1.4, 25, 0.6, fiber: 2.6, [.immunity, .energy]),
        f("kiwi", "Kiwi", .fruit, "2 fruits", 84, 1.6, 20, 0.7, fiber: 4.2, [.sleep, .immunity], "Studies link kiwi before bed with better sleep."),
        f("pear", "Pear", .fruit, "1 medium", 101, 0.6, 27, 0.2, fiber: 5.5, [.gut]),
        f("peach", "Peach", .fruit, "1 medium", 59, 1.4, 14, 0.4, fiber: 2.3, [.immunity]),
        f("tart-cherry", "Tart Cherry Juice", .fruit, "8 oz", 140, 1, 34, 0, [.sleep, .antiInflammatory, .recovery], "May reduce muscle soreness and help sleep."),
        f("raisins", "Raisins", .fruit, "1/4 cup", 123, 1.3, 33, 0.2, fiber: 1.5, [.energy, .iron]),
        f("dates", "Medjool Dates", .fruit, "2 dates", 133, 0.9, 36, 0.1, fiber: 3.2, [.energy], "Nature's energy gel."),
        f("dried-apricots", "Dried Apricots", .fruit, "1/4 cup", 78, 1.1, 20, 0.2, fiber: 2.4, [.iron, .energy]),
        f("avocado", "Avocado", .fruit, "1/2 fruit", 160, 2, 8.5, 14.7, fiber: 6.7, [.heart], "Healthy fats and potassium."),
        f("applesauce", "Applesauce", .fruit, "1 cup", 102, 0.4, 27, 0.2, fiber: 2.7, [.energy], "Easy on the stomach before games."),
        f("cantaloupe", "Cantaloupe", .fruit, "1 cup", 54, 1.3, 13, 0.3, fiber: 1.4, [.hydration, .immunity]),
    ]

    static let veg: [Food] = [
        f("broccoli", "Broccoli", .vegetable, "1 cup cooked", 55, 3.7, 11, 0.6, fiber: 5.1, [.immunity, .bones]),
        f("spinach", "Spinach", .vegetable, "2 cups raw", 14, 1.7, 2.2, 0.2, fiber: 1.3, [.iron, .bones]),
        f("carrots", "Carrots", .vegetable, "1 cup", 52, 1.2, 12, 0.3, fiber: 3.6, [.immunity]),
        f("sweet-potato", "Sweet Potato", .vegetable, "1 medium", 112, 2, 26, 0.1, fiber: 3.9, [.energy, .immunity], "Slow-burning carbs. Great the night before a game."),
        f("potato", "Baked Potato", .vegetable, "1 medium", 161, 4.3, 37, 0.2, fiber: 3.8, [.energy, .heart]),
        f("kale", "Kale", .vegetable, "1 cup", 33, 2.2, 6, 0.5, fiber: 2.6, [.bones, .immunity]),
        f("bell-pepper", "Bell Pepper", .vegetable, "1 cup", 30, 1, 7, 0.3, fiber: 2.5, [.immunity]),
        f("tomato", "Tomatoes", .vegetable, "1 cup", 32, 1.6, 7, 0.4, fiber: 2.2, [.heart, .antiInflammatory]),
        f("cucumber", "Cucumber", .vegetable, "1 cup", 16, 0.7, 3.8, 0.1, fiber: 0.5, [.hydration]),
        f("green-beans", "Green Beans", .vegetable, "1 cup", 44, 2.4, 10, 0.4, fiber: 4, [.gut]),
        f("salad", "Mixed Green Salad", .vegetable, "2 cups", 20, 1.5, 4, 0.2, fiber: 2, [.immunity]),
        f("corn", "Corn", .vegetable, "1 cup", 132, 5, 29, 1.8, fiber: 3.6, [.energy]),
        f("peas", "Green Peas", .vegetable, "1 cup", 117, 8, 21, 0.6, fiber: 7.4, [.gut]),
        f("beets", "Beets", .vegetable, "1 cup", 58, 2.2, 13, 0.2, fiber: 3.8, [.heart], "Nitrates may boost endurance."),
        f("mushrooms", "Mushrooms", .vegetable, "1 cup", 15, 2.2, 2.3, 0.2, fiber: 0.7, [.immunity]),
        f("brussels", "Brussels Sprouts", .vegetable, "1 cup cooked", 56, 4, 11, 0.8, fiber: 4.1, [.immunity, .gut]),
        f("zucchini", "Zucchini", .vegetable, "1 cup", 20, 1.5, 4, 0.4, fiber: 1.2, [.hydration]),
        f("cauliflower", "Cauliflower", .vegetable, "1 cup", 25, 2, 5, 0.3, fiber: 2, [.immunity]),
        f("asparagus", "Asparagus", .vegetable, "1 cup", 27, 2.9, 5.2, 0.2, fiber: 2.8, [.gut]),
    ]

    static let grains: [Food] = [
        f("oatmeal", "Oatmeal", .grain, "1 cup cooked", 166, 5.9, 28, 3.6, fiber: 4, [.energy, .heart, .gut], "Classic pre-game breakfast."),
        f("white-rice", "White Rice", .grain, "1 cup cooked", 205, 4.3, 45, 0.4, fiber: 0.6, [.energy], "Easy to digest. Great before games."),
        f("brown-rice", "Brown Rice", .grain, "1 cup cooked", 216, 5, 45, 1.8, fiber: 3.5, [.energy, .gut]),
        f("wheat-bread", "Whole Wheat Bread", .grain, "1 slice", 81, 4, 14, 1.1, fiber: 1.9, [.energy, .gut]),
        f("white-bread", "White Bread", .grain, "1 slice", 75, 2.6, 14, 1, fiber: 0.8, [.energy]),
        f("bagel", "Bagel", .grain, "1 medium", 277, 11, 55, 1.4, fiber: 2.4, [.energy]),
        f("pasta", "Pasta", .grain, "1 cup cooked", 221, 8.1, 43, 1.3, fiber: 2.5, [.energy], "Carb-load the night before games."),
        f("wheat-pasta", "Whole Wheat Pasta", .grain, "1 cup cooked", 174, 7.5, 37, 0.8, fiber: 6.3, [.energy, .gut]),
        f("quinoa", "Quinoa", .grain, "1 cup cooked", 222, 8.1, 39, 3.6, fiber: 5.2, [.recovery, .iron, .energy]),
        f("tortilla", "Flour Tortilla", .grain, "1 large", 218, 5.7, 36, 5.4, fiber: 2.1, [.energy]),
        f("granola", "Granola", .grain, "1/2 cup", 300, 7, 32, 15, fiber: 4, [.energy]),
        f("cereal", "Cheerios-style Cereal", .grain, "1 cup", 100, 3, 20, 2, fiber: 3, [.iron, .energy]),
        f("pancakes", "Pancakes", .grain, "2 medium", 350, 8, 44, 14, fiber: 1.5, [.energy]),
        f("waffles", "Frozen Waffles", .grain, "2 waffles", 190, 4, 30, 6, fiber: 1, [.energy]),
        f("english-muffin", "English Muffin", .grain, "1 muffin", 134, 4.4, 26, 1, fiber: 2, [.energy]),
        f("rice-cakes", "Rice Cakes", .grain, "2 cakes", 70, 1.4, 15, 0.6, fiber: 0.8, [.energy]),
        f("couscous", "Couscous", .grain, "1 cup cooked", 176, 6, 36, 0.3, fiber: 2.2, [.energy]),
        f("toast-jam", "Toast with Jam", .grain, "2 slices", 230, 6, 44, 3, fiber: 2.5, [.energy], "Quick, light pre-game carbs."),
        f("cream-of-rice", "Cream of Rice", .grain, "1 cup cooked", 127, 2.2, 28, 0.2, [.energy]),
    ]

    static let protein: [Food] = [
        f("chicken-breast", "Chicken Breast", .protein, "4 oz cooked", 187, 35, 0, 4, [.recovery], "Lean protein staple."),
        f("chicken-thigh", "Chicken Thigh", .protein, "4 oz cooked", 230, 28, 0, 13, [.recovery, .iron]),
        f("ground-beef", "Ground Beef (90%)", .protein, "4 oz cooked", 200, 23, 0, 11, [.recovery, .iron]),
        f("steak", "Sirloin Steak", .protein, "4 oz cooked", 230, 31, 0, 11, [.recovery, .iron], "Iron, zinc and B12."),
        f("salmon", "Salmon", .protein, "4 oz cooked", 233, 25, 0, 14, [.antiInflammatory, .heart, .recovery, .brain], "Omega-3s help with inflammation and recovery."),
        f("tuna", "Canned Tuna", .protein, "1 can (5 oz)", 120, 26, 0, 1, [.recovery]),
        f("eggs", "Eggs", .protein, "2 large", 143, 12.6, 0.7, 9.5, [.recovery, .brain]),
        f("egg-whites", "Egg Whites", .protein, "1/2 cup", 63, 13, 1, 0, [.recovery]),
        f("turkey-breast", "Turkey Breast", .protein, "4 oz", 153, 34, 0, 1, [.recovery, .sleep]),
        f("ground-turkey", "Ground Turkey", .protein, "4 oz cooked", 170, 22, 0, 9, [.recovery]),
        f("shrimp", "Shrimp", .protein, "4 oz", 112, 27, 0, 0.3, [.recovery]),
        f("pork-chop", "Pork Chop", .protein, "4 oz", 220, 30, 0, 10, [.recovery]),
        f("cod", "Cod", .protein, "4 oz", 102, 22, 0, 0.8, [.recovery]),
        f("sardines", "Sardines", .protein, "1 can", 191, 22.6, 0, 10.5, [.antiInflammatory, .bones]),
        f("tofu", "Tofu", .protein, "1/2 cup", 94, 10, 2.3, 6, [.bones, .recovery]),
        f("black-beans", "Black Beans", .protein, "1 cup", 227, 15, 41, 0.9, fiber: 15, [.gut, .iron, .energy]),
        f("chickpeas", "Chickpeas", .protein, "1 cup", 269, 14.5, 45, 4.2, fiber: 12.5, [.gut]),
        f("lentils", "Lentils", .protein, "1 cup cooked", 230, 18, 40, 0.8, fiber: 15.6, [.iron, .gut]),
        f("deli-turkey", "Deli Turkey", .protein, "2 oz", 60, 10, 2, 1, [.recovery]),
        f("bacon", "Bacon", .protein, "3 slices", 130, 9, 0.4, 10),
        f("whey", "Protein Shake (whey)", .protein, "1 scoop", 120, 24, 3, 1.5, [.recovery], "20–40 g protein within 2 hours after training."),
        f("protein-bar", "Protein Bar", .protein, "1 bar", 210, 20, 23, 7, fiber: 3, [.recovery]),
        f("jerky", "Beef Jerky", .protein, "1 oz", 116, 9.4, 3.1, 7.3, [.recovery, .iron]),
    ]

    static let dairy: [Food] = [
        f("milk", "Milk (2%)", .dairy, "1 cup", 122, 8, 12, 4.8, [.bones, .recovery, .hydration]),
        f("choc-milk", "Chocolate Milk", .dairy, "1 cup", 190, 8, 26, 5, [.recovery, .hydration], "Near-perfect carb-to-protein ratio after games."),
        f("greek-yogurt", "Greek Yogurt (plain)", .dairy, "3/4 cup", 100, 17, 6, 0.7, [.recovery, .gut, .bones]),
        f("yogurt", "Flavored Yogurt", .dairy, "6 oz", 150, 6, 26, 2, [.gut, .bones]),
        f("cottage-cheese", "Cottage Cheese", .dairy, "1/2 cup", 110, 12, 5, 5, [.recovery, .sleep], "Slow casein protein. Good before bed."),
        f("cheddar", "Cheddar Cheese", .dairy, "1 oz", 115, 7, 0.4, 9.4, [.bones]),
        f("string-cheese", "String Cheese", .dairy, "1 stick", 80, 7, 1, 6, [.bones, .recovery]),
        f("mozzarella", "Mozzarella", .dairy, "1 oz", 85, 6, 1, 6, [.bones]),
        f("kefir", "Kefir", .dairy, "1 cup", 110, 9, 12, 2.5, [.gut, .bones]),
        f("almond-milk", "Almond Milk", .dairy, "1 cup", 39, 1.5, 3.4, 2.5, [.bones]),
        f("butter", "Butter", .dairy, "1 tbsp", 102, 0.1, 0, 11.5),
        f("ice-cream", "Ice Cream", .dairy, "1/2 cup", 137, 2.3, 16, 7),
    ]

    static let fats: [Food] = [
        f("peanut-butter", "Peanut Butter", .fats, "2 tbsp", 190, 7, 7, 16, fiber: 2, [.energy, .heart]),
        f("almonds", "Almonds", .fats, "1 oz (23)", 164, 6, 6, 14, fiber: 3.5, [.heart]),
        f("walnuts", "Walnuts", .fats, "1 oz", 185, 4.3, 3.9, 18.5, fiber: 1.9, [.antiInflammatory, .brain]),
        f("cashews", "Cashews", .fats, "1 oz", 157, 5.2, 8.6, 12.4, fiber: 0.9, [.heart]),
        f("trail-mix", "Trail Mix", .fats, "1/4 cup", 175, 5, 16, 11, fiber: 2, [.energy]),
        f("olive-oil", "Olive Oil", .fats, "1 tbsp", 119, 0, 0, 13.5, [.heart, .antiInflammatory]),
        f("chia", "Chia Seeds", .fats, "2 tbsp", 138, 4.7, 12, 8.7, fiber: 9.8, [.antiInflammatory, .gut]),
        f("sunflower-seeds", "Sunflower Seeds", .fats, "1 oz", 165, 5.5, 7, 14, fiber: 3, [.heart]),
        f("pumpkin-seeds", "Pumpkin Seeds", .fats, "1 oz", 158, 8.5, 3, 14, fiber: 1.7, [.iron, .sleep]),
        f("hummus", "Hummus", .fats, "1/4 cup", 104, 5, 9, 6, fiber: 2.4, [.gut, .heart]),
        f("almond-butter", "Almond Butter", .fats, "2 tbsp", 196, 6.7, 6, 17.8, fiber: 3.3, [.heart]),
    ]

    static let snacks: [Food] = [
        f("granola-bar", "Granola Bar", .snack, "1 bar", 120, 2, 20, 4, fiber: 1, [.energy]),
        f("popcorn", "Popcorn (air-popped)", .snack, "3 cups", 93, 3, 19, 1, fiber: 3.5, [.gut]),
        f("chips", "Potato Chips", .snack, "1 oz", 152, 2, 15, 10),
        f("goldfish", "Cheese Crackers", .snack, "55 pieces", 140, 3, 20, 5, [.energy]),
        f("pretzels", "Pretzels", .snack, "1 oz", 108, 2.9, 23, 0.8, fiber: 1, [.energy], "Salty carbs. Good during long tournament days."),
        f("fig-bars", "Fig Bars", .snack, "2 bars", 200, 2, 40, 3, fiber: 2, [.energy]),
        f("fruit-snacks", "Fruit Snacks", .snack, "1 pouch", 80, 0, 19, 0, [.energy]),
        f("pbj", "PB&J Sandwich", .snack, "1 sandwich", 380, 13, 46, 17, fiber: 4, [.energy], "The dressing-room classic. Eat 2–3 hours before puck drop."),
        f("smoothie", "Fruit & Yogurt Smoothie", .snack, "16 oz", 300, 12, 58, 3, fiber: 4, [.recovery, .energy, .immunity]),
        f("rice-krispie", "Rice Crispy Treat", .snack, "1 bar", 90, 1, 17, 2.5, [.energy]),
        f("apple-pb", "Apple with Peanut Butter", .snack, "1 apple + 2 tbsp", 285, 7.5, 32, 16, fiber: 6.4, [.energy, .heart]),
        f("veggies-hummus", "Veggies & Hummus", .snack, "1 cup + 1/4 cup", 150, 6, 18, 6, fiber: 5, [.gut, .immunity]),
        f("crackers-cheese", "Crackers & Cheese", .snack, "6 crackers + 1 oz", 230, 9, 16, 15, [.bones]),
    ]

    static let meals: [Food] = [
        f("chicken-rice-bowl", "Chicken & Rice Bowl", .meal, "1 bowl", 550, 40, 65, 12, fiber: 4, [.recovery, .energy], "Ideal pre-game meal 3–4 hours out."),
        f("spaghetti", "Spaghetti with Meat Sauce", .meal, "1.5 cups", 450, 23, 58, 14, fiber: 5, [.energy, .recovery]),
        f("turkey-sandwich", "Turkey Sandwich", .meal, "1 sandwich", 350, 24, 40, 9, fiber: 4, [.recovery, .energy]),
        f("chicken-burrito", "Chicken Burrito", .meal, "1 burrito", 650, 35, 75, 22, fiber: 9, [.energy, .recovery]),
        f("pizza", "Cheese Pizza", .meal, "1 slice", 285, 12, 36, 10, fiber: 2.5, [.energy]),
        f("burger", "Hamburger", .meal, "1 burger", 540, 30, 40, 28, fiber: 2, [.recovery, .iron]),
        f("stir-fry", "Chicken Stir Fry with Rice", .meal, "1 plate", 500, 32, 60, 14, fiber: 4, [.recovery, .energy, .immunity]),
        f("chicken-salad", "Grilled Chicken Salad", .meal, "1 bowl", 350, 32, 12, 18, fiber: 5, [.recovery, .immunity]),
        f("omelette", "Veggie Omelette (3 eggs)", .meal, "1 omelette", 280, 20, 5, 20, fiber: 1.5, [.recovery]),
        f("tacos", "Beef Tacos", .meal, "2 tacos", 340, 18, 26, 18, fiber: 3, [.recovery, .iron]),
        f("mac-cheese", "Mac & Cheese", .meal, "1 cup", 350, 14, 48, 12, fiber: 2, [.energy]),
        f("chicken-soup", "Chicken Noodle Soup", .meal, "1 cup", 120, 8, 14, 3, fiber: 1, [.hydration, .immunity]),
        f("sushi", "Sushi Roll", .meal, "8 pieces", 300, 10, 50, 6, fiber: 2, [.energy]),
        f("grilled-cheese", "Grilled Cheese", .meal, "1 sandwich", 390, 14, 30, 24, fiber: 1.5, [.bones]),
        f("breakfast-burrito", "Breakfast Burrito", .meal, "1 burrito", 400, 18, 40, 18, fiber: 3, [.energy, .recovery]),
        f("french-toast", "French Toast", .meal, "2 slices", 300, 10, 36, 12, fiber: 1.5, [.energy]),
        f("wings", "Chicken Wings", .meal, "6 wings", 450, 40, 0, 30, [.recovery]),
        f("fries", "French Fries", .meal, "medium", 365, 4, 48, 17, fiber: 4.4),
        f("salmon-dinner", "Salmon, Rice & Veggies", .meal, "1 plate", 600, 35, 60, 20, fiber: 5, [.recovery, .antiInflammatory, .energy], "Textbook recovery dinner."),
        f("eggs-toast", "Eggs & Toast", .meal, "2 eggs + 2 slices", 305, 20, 29, 12, fiber: 3.8, [.recovery, .energy]),
        f("oats-pb-banana", "Oats with PB & Banana", .meal, "1 bowl", 460, 14, 63, 19, fiber: 9, [.energy, .heart], "Game-day breakfast."),
    ]

    static let drinks: [Food] = [
        f("water", "Water", .drink, "8 oz", 0, 0, 0, 0, [.hydration]),
        f("sports-drink", "Sports Drink", .drink, "20 oz", 140, 0, 34, 0, [.hydration, .energy], "Electrolytes for long practices and tournaments."),
        f("electrolyte-zero", "Electrolyte Drink (zero sugar)", .drink, "16 oz", 10, 0, 2, 0, [.hydration]),
        f("coconut-water", "Coconut Water", .drink, "1 cup", 46, 1.7, 9, 0.5, [.hydration]),
        f("oj", "Orange Juice", .drink, "8 oz", 112, 1.7, 26, 0.5, [.immunity, .energy]),
        f("apple-juice", "Apple Juice", .drink, "8 oz", 114, 0.2, 28, 0.3, [.energy]),
        f("coffee", "Coffee (black)", .drink, "8 oz", 2, 0.3, 0, 0, [.brain]),
        f("latte", "Latte", .drink, "16 oz", 190, 12, 18, 7, [.bones]),
        f("green-tea", "Green Tea", .drink, "8 oz", 2, 0, 0, 0, [.antiInflammatory, .brain]),
        f("soda", "Soda", .drink, "12 oz", 140, 0, 39, 0),
        f("energy-drink", "Energy Drink", .drink, "8 oz", 110, 0, 28, 0, [], "Big caffeine hit. Avoid late in the day."),
    ]

    static let sweets: [Food] = [
        f("cookie", "Cookie", .sweet, "1 large", 220, 2, 30, 11, fiber: 1),
        f("donut", "Donut", .sweet, "1 donut", 250, 3, 30, 14, fiber: 1),
        f("candy-bar", "Candy Bar", .sweet, "1 bar", 250, 4, 33, 12, fiber: 1),
        f("dark-chocolate", "Dark Chocolate", .sweet, "1 oz", 170, 2.2, 13, 12, fiber: 3, [.antiInflammatory]),
        f("gummies", "Gummy Candy", .sweet, "1 oz", 100, 1.5, 23, 0, [.energy]),
    ]

    /// Foods worth suggesting for a situation.
    static func ideas(_ meal: Meal) -> [Food] {
        let ids: [String]
        switch meal {
        case .preGame: ids = ["pbj", "banana", "chicken-rice-bowl", "oats-pb-banana", "toast-jam", "pretzels", "applesauce", "dates", "sports-drink"]
        case .postWorkout: ids = ["choc-milk", "whey", "greek-yogurt", "smoothie", "salmon-dinner", "turkey-sandwich", "tart-cherry", "eggs-toast"]
        case .breakfast: ids = ["oats-pb-banana", "eggs-toast", "greek-yogurt", "breakfast-burrito", "oatmeal", "omelette"]
        case .dinner: ids = ["salmon-dinner", "spaghetti", "stir-fry", "chicken-rice-bowl", "sweet-potato"]
        case .snack: ids = ["apple-pb", "string-cheese", "trail-mix", "veggies-hummus", "greek-yogurt", "jerky"]
        case .lunch: ids = ["turkey-sandwich", "chicken-salad", "chicken-burrito", "chicken-rice-bowl"]
        case .drinks: ids = ["water", "choc-milk", "coconut-water", "sports-drink", "tart-cherry"]
        }
        return ids.compactMap { byID[$0] }
    }
}

/// Open Food Facts lookups (free, no key). Values come back per serving when available, otherwise per 100 g.
enum FoodAPI {
    private static let fields = "code,product_name,brands,nutriments,serving_size"

    private static func request(_ url: URL) -> URLRequest {
        var r = URLRequest(url: url, timeoutInterval: 15)
        r.setValue("Edgework/1.0 (personal iOS app)", forHTTPHeaderField: "User-Agent")
        return r
    }

    static func search(_ query: String) async -> [Food] {
        var c = URLComponents(string: "https://world.openfoodfacts.org/cgi/search.pl")!
        c.queryItems = [
            .init(name: "search_terms", value: query), .init(name: "search_simple", value: "1"),
            .init(name: "action", value: "process"), .init(name: "json", value: "1"),
            .init(name: "page_size", value: "25"), .init(name: "fields", value: fields),
        ]
        guard let url = c.url, let result = try? await URLSession.shared.data(for: request(url)),
              let json = try? JSONSerialization.jsonObject(with: result.0) as? [String: Any],
              let products = json["products"] as? [[String: Any]] else { return [] }
        return products.compactMap(food(from:))
    }

    static func barcode(_ code: String) async -> Food? {
        guard let url = URL(string: "https://world.openfoodfacts.org/api/v2/product/\(code).json?fields=\(fields)"),
              let result = try? await URLSession.shared.data(for: request(url)),
              let json = try? JSONSerialization.jsonObject(with: result.0) as? [String: Any],
              let product = json["product"] as? [String: Any] else { return nil }
        var p = product
        if p["code"] == nil { p["code"] = code }
        return food(from: p)
    }

    static func food(from p: [String: Any]) -> Food? {
        guard let name = (p["product_name"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines), !name.isEmpty else { return nil }
        let code = (p["code"] as? String) ?? name
        let brand = (p["brands"] as? String)?.split(separator: ",").first.map { $0.trimmingCharacters(in: .whitespaces) }
        let n = p["nutriments"] as? [String: Any] ?? [:]
        func num(_ k: String) -> Double? {
            if let d = n[k] as? Double { return d }
            if let i = n[k] as? Int { return Double(i) }
            if let s = n[k] as? String { return Double(s) }
            return nil
        }
        let servingText = (p["serving_size"] as? String)?.trimmingCharacters(in: .whitespaces)
        let perServing = num("energy-kcal_serving") != nil && !(servingText ?? "").isEmpty
        let sfx = perServing ? "_serving" : "_100g"
        guard let kcal = num("energy-kcal" + sfx) ?? num("energy-kcal") else { return nil }
        let protein = num("proteins" + sfx) ?? 0
        let carbs = num("carbohydrates" + sfx) ?? 0
        let fat = num("fat" + sfx) ?? 0
        let fiber = num("fiber" + sfx) ?? 0
        var benefits: [FoodBenefit] = []
        if protein >= 15 { benefits.append(.recovery) }
        if carbs >= 25 { benefits.append(.energy) }
        if fiber >= 5 { benefits.append(.gut) }
        let display = brand.map { "\(name) · \($0)" } ?? name
        return Food(id: "off-\(code)", name: display, group: .snack, serving: perServing ? (servingText ?? "1 serving") : "100 g",
                    kcal: kcal.rounded(), protein: (protein * 10).rounded() / 10, carbs: (carbs * 10).rounded() / 10,
                    fat: (fat * 10).rounded() / 10, fiber: (fiber * 10).rounded() / 10, benefits: benefits, note: "",
                    source: "Open Food Facts")
    }
}
