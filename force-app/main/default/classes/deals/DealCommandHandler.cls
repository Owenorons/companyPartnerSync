public interface DealCommandHandler {
  void validate(DealCommandContext context);
  void execute(DealCommandContext context);
}
