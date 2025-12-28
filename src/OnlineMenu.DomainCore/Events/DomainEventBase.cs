namespace OnlineMenu.DomainCore.Events;

/// <summary>
/// Base class for all domain events.
/// Domain events represent something that happened in the domain that domain experts care about.
/// </summary>
public abstract class DomainEventBase
{
  /// <summary>
  /// Gets the date and time when the event occurred.
  /// </summary>
  public DateTime DateOccurred { get; protected set; } = DateTime.UtcNow;
}
