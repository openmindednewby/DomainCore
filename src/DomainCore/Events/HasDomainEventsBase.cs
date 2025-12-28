using DomainCore.Interfaces;

namespace DomainCore.Events;

/// <summary>
/// Base class for entities that can raise domain events.
/// Provides functionality to register and clear domain events.
/// </summary>
public abstract class HasDomainEventsBase : IAggregateRoot
{
  private readonly List<DomainEventBase> _domainEvents = new();

  /// <summary>
  /// Gets the collection of domain events raised by this entity.
  /// </summary>
  public IReadOnlyCollection<DomainEventBase> DomainEvents => _domainEvents.AsReadOnly();

  /// <summary>
  /// Registers a new domain event.
  /// </summary>
  /// <param name="domainEvent">The domain event to register.</param>
  protected void RegisterDomainEvent(DomainEventBase domainEvent)
  {
    _domainEvents.Add(domainEvent);
  }

  /// <summary>
  /// Clears all domain events.
  /// This is typically called after the events have been dispatched.
  /// </summary>
  public void ClearDomainEvents()
  {
    _domainEvents.Clear();
  }
}
