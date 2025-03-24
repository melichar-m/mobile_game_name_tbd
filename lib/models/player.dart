class Player {
  double speed = 5.0;
  double health = 100.0;
  double maxHealth = 100.0;
  double damage = 10.0;
  double experience = 0.0;
  int level = 1;

  void takeDamage(double damage) {
    health = (health - damage).clamp(0, maxHealth);
  }

  void heal(double amount) {
    health = (health + amount).clamp(0, maxHealth);
  }

  void gainExperience(double amount) {
    experience += amount;
    // Simple leveling system
    if (experience >= level * 100) {
      levelUp();
    }
  }

  void levelUp() {
    level++;
    maxHealth += 20;
    health = maxHealth;
    damage += 2;
    experience = 0;
  }
} 