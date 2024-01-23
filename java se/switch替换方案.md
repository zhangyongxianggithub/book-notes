- 使用注册式的Manager
- 通过实现enum方法
  ```java
    public enum PlayerTypes { TENNIS {
    @Override
    public Player createPlayer() {
        return new TennisPlayer();
    }
    },
    FOOTBALL {
    @Override
    public Player createPlayer() {
        return new FootballPlayer();
    }
    },
    SNOOKER {
    @Override
        public Player createPlayer() {
            return new SnookerPlayer();
        }
    };

    public abstract Player createPlayer();
    }
  ```
- 使用命令设计模式
  ```java
    public interface Command {

    Player create();
    }
  ```
  ```java
    public class CreatePlayerCommand {

    private static final Map<String, Command> PLAYERS;

    static {
        final Map<String, Command> players = new HashMap<>();
        players.put("TENNIS", new Command() {
            @Override
            public Player create() {
                return new TennisPlayer();
            }
        });

        players.put("FOOTBALL", new Command() {
            @Override
            public Player create() {
                return new FootballPlayer();
            }
        });

        players.put("SNOOKER", new Command() {
            @Override
            public Player create() {
                return new SnookerPlayer();
            }
        });

        PLAYERS = Collections.unmodifiableMap(players);
    }

    public Player createPlayer(String playerType) {
        Command command = PLAYERS.get(playerType);

        if (command == null) {
            throw new IllegalArgumentException("Invalid player type: "
                + playerType);
        }

        return command.create();
    }
    }
  ```
- Java8的`Supplier`接口
  ```java
    public class PlayerSupplier {
    private static final Map<String, Supplier<Player>>
        PLAYER_SUPPLIER;

    static {
        final Map<String, Supplier<Player>>
            players = new HashMap<>();
        players.put("TENNIS", TennisPlayer::new);
        players.put("FOOTBALL", FootballPlayer::new);
        players.put("SNOOKER", SnookerPlayer::new);

        PLAYER_SUPPLIER = Collections.unmodifiableMap(players);
    }

    public Player supplyPlayer(String playerType) {
        Supplier<Player> player = PLAYER_SUPPLIER.get(playerType);

        if (player == null) {
            throw new IllegalArgumentException("Invalid player type: "
                + playerType);
        }
        return player.get();
    }
    }
  ```
- 自定义函数式接口
  ```java
    @FunctionalInterface
    public interface TriFunction<T, U, V, R> {

    R apply(T t, U u, V v);
    }

    public final class FunctionalStatistics {

    private FunctionalStatistics() {
        throw new AssertionError();
    }

    private static final Map<String, TriFunction<TennisPlayer,
            Period, String, String>>
        STATISTICS = new HashMap<>();

    static {
        STATISTICS.put("SERVE", Statistics::computeServeTrend);
        STATISTICS.put("FOREHAND", Statistics::computeForehandTrend);
        STATISTICS.put("BACKHAND", Statistics::computeBackhandTrend);
    }

    public static String computeTrend(TennisPlayer tennisPlayer,
        Period period, String owner, String trend) {
        TriFunction<TennisPlayer, Period, String, String>
                function = STATISTICS.get(trend);

        if (function == null) {
            throw new IllegalArgumentException("Invalid trend type: "
                + trend);
            }

        return function.apply(tennisPlayer, period, owner);
    }
    }
  ```
- 抽象工厂
  ```java
    public interface AbstractPlayerFactory {

    public Player createPlayer(Type type, int delta);
    }
  ```
  ```java
    public class PlayerFactory implements AbstractPlayerFactory {

    @Override
    public Player createPlayer(Type type, int delta) {
        switch (type) {
            case TENNIS:
                return new TennisPlayer(type, delta);
            case FOOTBALL:
                return new FootballPlayer(type, delta);
            case SNOOKER:
                return new SnookerPlayer(type, delta);

            default:
            throw new IllegalArgumentException("Invalid player type: "
                + type);
        }
    }
    }
  ```
- 状态设计模式
  ```java
    public interface PlayerState {

    void register();
    void unregister();
    }
  ```
  