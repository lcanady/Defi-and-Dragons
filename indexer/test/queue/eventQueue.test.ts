import { EventQueue } from '../../src/services/EventQueue';
import { CharacterEvent } from '../../src/types';

describe('Event Queue', () => {
  let eventQueue: EventQueue;

  beforeEach(() => {
    eventQueue = new EventQueue(false); // Disable auto-processing for tests
  });

  it('should queue new events', async () => {
    const event: CharacterEvent = {
      type: 'CHARACTER_CREATED',
      tokenId: 1,
      owner: '0x123',
      timestamp: Math.floor(Date.now() / 1000),
    };

    await eventQueue.push(event);
    expect(eventQueue.size()).toBe(1);
  });

  it('should process events in order', async () => {
    const events: CharacterEvent[] = [
      {
        type: 'CHARACTER_CREATED',
        tokenId: 1,
        owner: '0x123',
        timestamp: Math.floor(Date.now() / 1000),
      },
      {
        type: 'CHARACTER_UPDATED',
        tokenId: 1,
        owner: '0x123',
        timestamp: Math.floor(Date.now() / 1000) + 1000,
      },
    ];

    const processedEvents: CharacterEvent[] = [];
    eventQueue.onProcess(async (event) => {
      processedEvents.push(event);
      return Promise.resolve();
    });

    await Promise.all(events.map(event => eventQueue.push(event)));
    await eventQueue.process();

    expect(processedEvents).toHaveLength(2);
    expect(processedEvents[0].type).toBe('CHARACTER_CREATED');
    expect(processedEvents[1].type).toBe('CHARACTER_UPDATED');
    expect(eventQueue.size()).toBe(0);
  });

  it('should handle errors during processing', async () => {
    const event: CharacterEvent = {
      type: 'CHARACTER_CREATED',
      tokenId: 1,
      owner: '0x123',
      timestamp: Math.floor(Date.now() / 1000),
    };

    const error = new Error('Processing failed');
    const errorHandler = jest.fn();

    eventQueue.onProcess(async () => {
      throw error;
    });

    eventQueue.onError(errorHandler);

    await eventQueue.push(event);
    await eventQueue.process();

    expect(errorHandler).toHaveBeenCalledWith(event, error);
    expect(eventQueue.size()).toBe(0); // Event should be removed after max retries
  });

  it('should clear the queue', async () => {
    const events: CharacterEvent[] = [
      {
        type: 'CHARACTER_CREATED',
        tokenId: 1,
        owner: '0x123',
        timestamp: Math.floor(Date.now() / 1000),
      },
      {
        type: 'CHARACTER_UPDATED',
        tokenId: 1,
        owner: '0x123',
        timestamp: Math.floor(Date.now() / 1000) + 1000,
      },
    ];

    await Promise.all(events.map(event => eventQueue.push(event)));
    expect(eventQueue.size()).toBe(2);

    eventQueue.clear();
    expect(eventQueue.size()).toBe(0);
  });

  it('should not process events when no processors are registered', async () => {
    const event: CharacterEvent = {
      type: 'CHARACTER_CREATED',
      tokenId: 1,
      owner: '0x123',
      timestamp: Math.floor(Date.now() / 1000),
    };

    await eventQueue.push(event);
    await eventQueue.process();

    expect(eventQueue.size()).toBe(1); // Event should remain in queue as no processors are registered
  });

  it('should handle auto-processing mode', async () => {
    const autoQueue = new EventQueue(true);
    const processedEvents: CharacterEvent[] = [];
    
    autoQueue.onProcess(async (event) => {
      processedEvents.push(event);
      return Promise.resolve();
    });

    const event: CharacterEvent = {
      type: 'CHARACTER_CREATED',
      tokenId: 1,
      owner: '0x123',
      timestamp: Math.floor(Date.now() / 1000),
    };

    await autoQueue.push(event);
    expect(processedEvents).toHaveLength(1);
    expect(autoQueue.size()).toBe(0);
  });
}); 