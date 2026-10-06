# Module LinkedIn::MemberData::Util <a id="module-LinkedIn-MemberData-Util"></a>

|  |  |
| --- | --- |
| **Defined in** | lib/linkedin/member_data/util.rb |

Conversions between epoch milliseconds (LinkedIn wire format) and Time.

- **@api** private

## Public Class Methods
### `epoch_ms(value)` <a id="method-c-epoch_ms"></a> <a id="epoch_ms-class_method"></a>
Converts a Time, Date or Integer to epoch milliseconds. Rounds down.
- **@api** private
- **@param** `value` [Time, Date, Integer, nil] an Integer is taken as epoch milliseconds.
A Date counts as midnight UTC.
- **@raise** [ArgumentError] when `value` is any other type.
- **@return** [Integer, nil] epoch milliseconds, or `nil` when `value` is `nil`.

**@example**
```ruby
LinkedIn::MemberData::Util.epoch_ms(Time.utc(2026, 9, 1))  # => 1788220800000
LinkedIn::MemberData::Util.epoch_ms(Date.new(2026, 9, 1))  # => 1788220800000 (midnight UTC)
LinkedIn::MemberData::Util.epoch_ms(1_788_220_800_000)     # => 1788220800000
LinkedIn::MemberData::Util.epoch_ms(nil)                   # => nil
```

### `time_from_ms(milliseconds)` <a id="method-c-time_from_ms"></a> <a id="time_from_ms-class_method"></a>
Converts epoch milliseconds to a UTC Time. Keeps sub-second precision.
- **@api** private
- **@param** `milliseconds` [Integer, nil] epoch milliseconds.
- **@return** [Time, nil] UTC Time, or `nil` when `milliseconds` is `nil`.
