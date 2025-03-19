import { CharacterEvent } from '@/types';

type EventProcessor = (event: CharacterEvent) => Promise<void>;
type ErrorHandler = (event: CharacterEvent, error: Error) => void;

export class EventQueue {
  private queue: CharacterEvent[] = [];
  private processors: EventProcessor[] = [];
  private errorHandlers: ErrorHandler[] = [];
  private isProcessing = false;
  private maxRetries = 3;
  private retryDelay = 1000;
  private autoProcess = true;

  constructor(autoProcess = true) {
    this.autoProcess = autoProcess;
  }

  async push(event: CharacterEvent): Promise<void> {
    this.queue.push(event);
    if (this.autoProcess && !this.isProcessing && this.processors.length > 0) {
      await this.process();
    }
  }

  onProcess(processor: EventProcessor): void {
    this.processors.push(processor);
  }

  onError(handler: ErrorHandler): void {
    this.errorHandlers.push(handler);
  }

  size(): number {
    return this.queue.length;
  }

  async process(): Promise<void> {
    if (this.isProcessing || this.processors.length === 0) return;
    this.isProcessing = true;

    try {
      // Sort events by timestamp
      this.queue.sort((a, b) => a.timestamp - b.timestamp);

      while (this.queue.length > 0) {
        const event = this.queue[0];
        let retries = 0;
        let success = false;

        while (retries < this.maxRetries && !success) {
          try {
            await Promise.all(
              this.processors.map(processor => processor(event))
            );
            success = true;
          } catch (error) {
            retries++;
            if (retries === this.maxRetries) {
              this.errorHandlers.forEach(handler => 
                handler(event, error as Error)
              );
            } else {
              await new Promise(resolve => 
                setTimeout(resolve, this.retryDelay * Math.pow(2, retries - 1))
              );
            }
          }
        }

        // Remove the event from the queue after processing (success or max retries)
        this.queue.shift();
      }
    } finally {
      this.isProcessing = false;
    }
  }

  clear(): void {
    this.queue = [];
  }

  removeProcessor(processor: EventProcessor): void {
    this.processors = this.processors.filter(p => p !== processor);
  }

  removeErrorHandler(handler: ErrorHandler): void {
    this.errorHandlers = this.errorHandlers.filter(h => h !== handler);
  }
} 