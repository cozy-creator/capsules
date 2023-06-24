// This makes up for the fact that you cannot delete shared objects in Sui

module ownership::destroyed {
    struct IsDestroyed has store { }
}